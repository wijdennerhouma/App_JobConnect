import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_state.dart';
import '../../core/api_config.dart';
import '../../services/user_service.dart';
import 'package:http/http.dart' as http;
import '../../models/user.dart';
import '../chat/chat_screen.dart';
import '../../core/app_settings.dart';
import '../../core/translations.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthState>();
      final userService = UserService(auth);
      final results = await userService.searchUsers(query);
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.watch<AppSettings>().language;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: lang.tr('search_placeholder_name'),
            border: InputBorder.none,
            hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
          style: theme.textTheme.bodyLarge,
          onSubmitted: _performSearch,
          onChanged: (value) {

            if (value.length > 2) {
              _performSearch(value);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _performSearch(_searchController.text),
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final lang = context.watch<AppSettings>().language;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(lang.tr('error_occurred'), style: theme.textTheme.titleMedium),
            Text(_error!, style: theme.textTheme.bodySmall),
          ],
        ),
      );
    }

    if (_results.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text(lang.tr('no_results_found'), style: theme.textTheme.titleMedium),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final user = _results[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipOval(
              child: user['avatar'] != null
                  ? Image.network(
                      '${ApiConfig.baseUrl}/uploads/avatars/${user['avatar']}',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 56,
                          height: 56,
                          color: theme.colorScheme.primaryContainer,
                          alignment: Alignment.center,
                          child: Text(
                            (user['name'] as String? ?? '?')[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      width: 56,
                      height: 56,
                      color: theme.colorScheme.primaryContainer,
                      alignment: Alignment.center,
                      child: Text(
                        (user['name'] as String? ?? '?')[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
            ),
            title: Text(
              user['name'] ?? 'Inconnu',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: user['type'] == 'entreprise' 
                        ? Colors.blue.withOpacity(0.1) 
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    user['type'] == 'entreprise' ? lang.tr('company') : lang.tr('candidate'),
                    style: TextStyle(
                      fontSize: 12,
                      color: user['type'] == 'entreprise' ? Colors.blue : Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (user['city'] != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: theme.disabledColor),
                      const SizedBox(width: 4),
                      Text(user['city'], style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
              ],
            ),
            trailing: Icon(Icons.chevron_right, color: theme.disabledColor),
            onTap: () {

              _showUserProfile(context, user);
            },
          ),
        );
      },
    );
  }

  void _showUserProfile(BuildContext context, Map<String, dynamic> user) {
    final lang = context.read<AppSettings>().language;
    final auth = context.read<AuthState>();
    final isMe = (user['_id']?.toString() ?? '') == (auth.userId ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  ClipOval(
                    child: user['avatar'] != null
                        ? Image.network(
                            '${ApiConfig.baseUrl}/uploads/avatars/${user['avatar']}',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[300],
                                alignment: Alignment.center,
                                child: Text(
                                  (user['name'] as String? ?? '?')[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 32),
                                ),
                              );
                            },
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            alignment: Alignment.center,
                            child: Text(
                              (user['name'] as String? ?? '?')[0].toUpperCase(),
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['name'] ?? 'Inconnu',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user['type'] == 'entreprise' ? lang.tr('company') : lang.tr('candidate'),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (user['bio'] != null) ...[
                Text(
                  lang.tr('bio'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(user['bio']),
                const Divider(height: 32),
              ],
              
              _buildInfoRow(context, Icons.email, lang.tr('email_label'), user['showEmail'] == true ? user['email'] : lang.tr('not_visible')),
              const SizedBox(height: 16),
              _buildInfoRow(context, Icons.phone, lang.tr('phone_label'), user['showPhoneNumber'] == true ? user['phoneNumber'] : lang.tr('not_visible')),
              const SizedBox(height: 16),
              _buildInfoRow(context, Icons.location_on, lang.tr('address_label'), '${user['address'] ?? ''} ${user['city'] ?? ''}'),
              
              if (!isMe) ...[
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final appUser = AppUser.fromJson(user);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(otherUser: appUser),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat),
                    label: Text(lang.tr('send_message')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(lang.tr('close')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).disabledColor),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }
}
