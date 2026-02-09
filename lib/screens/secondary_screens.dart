
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../services/supabase_service.dart'; // Real service
// import '../services/mock_service.dart'; // REMOVE MOCK

import 'package:geolocator/geolocator.dart';
import 'package:timeago/timeago.dart' as timeago;

// --- Map Screen ---
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LocationPermission? _permission;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    setState(() => _permission = permission);
  }

  @override
  Widget build(BuildContext context) {
    bool hasPermission = _permission == LocationPermission.always || _permission == LocationPermission.whileInUse;

    return Scaffold(
      body: Stack(
        children: [
          // Full Screen Map Placeholder
          Container(
            height: double.infinity,
            width: double.infinity,
             decoration: BoxDecoration(
              color: Colors.grey[200],
              image: hasPermission ? const DecorationImage(
                image: NetworkImage('https://maps.googleapis.com/maps/api/staticmap?center=37.7749,-122.4194&zoom=13&size=800x1200&key=AIzaSyBObagDSkGta1Jv7hwRgL9DX2UxvLQQJnY'),
                fit: BoxFit.cover,
              ) : null,
            ),
            child: hasPermission 
              ? Container(color: Colors.black.withOpacity(0.1)) // Overlay
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off, color: Colors.grey, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Location permission not given',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _checkPermission,
                        child: const Text('Grant Permission'),
                      ),
                    ],
                  ),
                ),
          ),
          
          // Search Bar Overlay
          Positioned(
            top: 60,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Search area...',
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                  ),
                  const Icon(Icons.filter_list, color: AppColors.primaryLight),
                ],
              ),
            ),
          ),

          // Bottom Sheet Preview (Mock)
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.accentLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.warning, color: AppColors.accentLight),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Structure Fire nearby',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '0.2 km away • Emergency',
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Chat Screen ---
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late Future<List<ChatConversation>> _conversationsFuture;

  @override
  void initState() {
    super.initState();
    _refreshConversations();
  }

  void _refreshConversations() {
    setState(() {
      _conversationsFuture = SupabaseService().getConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder<List<ChatConversation>>(
        future: _conversationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                   const SizedBox(height: 16),
                   Text('No messages yet', style: GoogleFonts.poppins(color: Colors.grey)),
                ],
              ),
            );
          }

          final chats = snapshot.data!;
          
          return RefreshIndicator(
            onRefresh: () async => _refreshConversations(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                return GestureDetector(
                  onTap: () async {
                    await context.push('/chat-detail?id=${chat.id}&name=${chat.otherUserName}&uid=${chat.otherUserId}');
                    _refreshConversations();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                          backgroundImage: chat.otherUserAvatar.isNotEmpty 
                             ? NetworkImage(chat.otherUserAvatar) 
                             : null,
                          child: chat.otherUserAvatar.isEmpty 
                             ? Text(chat.otherUserName[0].toUpperCase(), style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold)) 
                             : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    chat.otherUserName,
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                                  ),
                                  Text(
                                    timeago.format(chat.lastMessageTime, locale: 'en_short'),
                                    style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                chat.lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// --- ProfileScreen ---
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<User?>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _refreshProfile();
  }

  void _refreshProfile() {
    setState(() {
      _profileFuture = SupabaseService().getCurrentUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<User?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          
          final user = snapshot.data;
          
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('User not found.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshProfile,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _refreshProfile();
              await _profileFuture;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        height: 200,
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                        ),
                      ),
                      Positioned(
                        bottom: -50,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 56,
                            backgroundImage: NetworkImage(user.avatarUrl.isNotEmpty 
                              ? user.avatarUrl 
                              : 'https://i.pravatar.cc/150?u=${user.id}'), // Fallback
                            onBackgroundImageError: (_, __) {},
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  Text(
                    user.name.isEmpty || user.name == 'Unknown' ? 'No Name Set' : user.name,
                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user.email.isEmpty ? 'No Email' : user.email, 
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatItem('Helps', user.helpCount.toString()),
                      Container(height: 30, width: 1, color: Colors.grey[300]),
                      _buildStatItem('Rating', user.rating.toStringAsFixed(1)),
                      Container(height: 30, width: 1, color: Colors.grey[300]),
                      _buildStatItem('Points', user.points.toString()),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Skills',
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        if (user.skills.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 16.0),
                            child: Text('No skills added yet. Edit profile to add some.', style: TextStyle(color: Colors.grey)),
                          ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: user.skills.map((skill) => Chip(
                            label: Text(skill),
                            backgroundColor: AppColors.primaryLight.withOpacity(0.1),
                            labelStyle: const TextStyle(color: AppColors.primaryLight),
                          )).toList(),
                        ),
                        const SizedBox(height: 32),
                        const Divider(),
                        // Moved Edit Profile up and made it more prominent
                        ListTile(
                          leading: const Icon(Icons.settings, color: Colors.grey),
                          title: const Text('App Settings'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/settings'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.edit, color: AppColors.primaryLight),
                          title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await context.push('/edit-profile');
                            if (mounted) {
                              _refreshProfile(); // Refresh data after editing
                            }
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.history),
                          title: const Text('Help History'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {},
                        ),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text('Logout', style: TextStyle(color: Colors.red)),
                          onTap: () async {
                             await SupabaseService().signOut();
                             if (context.mounted) context.go('/login');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
