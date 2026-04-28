import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'global_state.dart';

class CitizenCommunityFeed extends StatefulWidget {
  const CitizenCommunityFeed({Key? key}) : super(key: key);

  static Future<void> seedDemoData(BuildContext context) async {
    final batch = FirebaseFirestore.instance.batch();
    final collection = FirebaseFirestore.instance.collection('feed_posts');

    final demoPosts = [
      {
        'authorName': 'Nagpur Health Dept',
        'authorUid': 'official_nagpur',
        'content': 'Heatwave Warning: Temperature in Nagpur expected to cross 45°C today. Stay hydrated and avoid outdoor activities between 12 PM - 4 PM.',
        'category': 'Hazard',
        'isOfficial': true,
        'timestamp': FieldValue.serverTimestamp(),
        'upvotes': ['user1', 'user2', 'user3', 'user4', 'user5'],
        'upvoteCount': 5,
        'downvotes': [],
        'imageUrl': '',
      },
      {
        'authorName': 'Rahul S.',
        'authorUid': 'citizen_rahul',
        'content': 'Heavy water-logging at Sitabuldi flyover after the morning downpour. Traffic is moving very slowly. Avoid this route if possible.',
        'category': 'Traffic',
        'isOfficial': false,
        'timestamp': FieldValue.serverTimestamp(),
        'upvotes': ['user6', 'user7', 'user8'],
        'upvoteCount': 3,
        'downvotes': [],
        'imageUrl': '',
      },
      {
        'authorName': 'Community Health Center',
        'authorUid': 'clinic_comm',
        'content': 'Free Blood Pressure check-up camp organized at Deekshabhoomi ground tomorrow morning from 8 AM. Open for all senior citizens.',
        'category': 'Medical Info',
        'isOfficial': false,
        'timestamp': FieldValue.serverTimestamp(),
        'upvotes': ['user9', 'user10'],
        'upvoteCount': 2,
        'downvotes': [],
        'imageUrl': '',
      }
    ];

    for (var post in demoPosts) {
      batch.set(collection.doc(), post);
    }

    await batch.commit();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nagpur Demo Data Seeded!'), backgroundColor: Colors.green));
    }
  }

  @override
  State<CitizenCommunityFeed> createState() => _CitizenCommunityFeedState();
}

class _CitizenCommunityFeedState extends State<CitizenCommunityFeed> {
  // Design System Colors
  static const Color background = Color(0xFFF1F4F9);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E8);
  static const Color surfaceVariant = Color(0xFFE0E3E8);
  static const Color onSurface = Color(0xFF181C20);
  static const Color onSurfaceVariant = Color(0xFF414754);
  static const Color primary = Color(0xFF0059BB);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF0070EA);
  static const Color onPrimaryContainer = Color(0xFFFEFCFF);
  static const Color outline = Color(0xFF717786);
  static const Color outlineVariant = Color(0xFFC1C6D7);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color primaryFixed = Color(0xFFD8E2FF);
  static const Color onPrimaryFixed = Color(0xFF001A41);

  String _selectedFilter = 'Hot'; // 'Hot', 'Local', 'Official'
  String _selectedTab = 'Community'; // 'Community', 'Health Feed'
  final ImagePicker _picker = ImagePicker();

  void _showCreatePostDialog() {
    final TextEditingController contentController = TextEditingController();
    String selectedCategory = 'Hazard';
    XFile? selectedImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Broadcast Update',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: onSurface),
              ),
              const SizedBox(height: 16),
              const Text('CATEGORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: outline)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Hazard', 'Traffic', 'Medical Info'].map((cat) {
                  final isSel = selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSel,
                    onSelected: (val) => setModalState(() => selectedCategory = cat),
                    selectedColor: primaryContainer,
                    labelStyle: TextStyle(color: isSel ? onPrimaryContainer : onSurfaceVariant),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: contentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share a critical update with the community...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              const Text('ATTACH MEDIA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: outline)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildMediaButton(Icons.camera_alt_outlined, () async {
                    final img = await _picker.pickImage(source: ImageSource.camera);
                    if (img != null) setModalState(() => selectedImage = img);
                  }),
                  const SizedBox(width: 12),
                  _buildMediaButton(Icons.photo_library_outlined, () async {
                    final img = await _picker.pickImage(source: ImageSource.gallery);
                    if (img != null) setModalState(() => selectedImage = img);
                  }),
                  const SizedBox(width: 16),
                  if (selectedImage != null)
                    Stack(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: outlineVariant),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: kIsWeb 
                            ? Image.network(selectedImage!.path, fit: BoxFit.cover)
                            : Image.file(File(selectedImage!.path), fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: -4,
                          right: -4,
                          child: GestureDetector(
                            onTap: () => setModalState(() => selectedImage = null),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (contentController.text.trim().isEmpty) return;
                    
                    await FirebaseFirestore.instance.collection('feed_posts').add({
                      'authorName': currentUser.name.isEmpty ? 'Citizen' : currentUser.name,
                      'authorUid': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
                      'content': contentController.text.trim(),
                      'category': selectedCategory,
                      'timestamp': FieldValue.serverTimestamp(),
                      'upvotes': [],
                      'downvotes': [],
                      'upvoteCount': 0,
                      'isOfficial': false,
                      'imageUrl': selectedImage?.path ?? '', // Saving local path for hackathon bypass
                    });
                    
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Post Broadcast', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: outlineVariant),
        ),
        child: Icon(icon, color: onSurfaceVariant),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostDialog,
        backgroundColor: primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Tab Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildTabChip('Community', Icons.people_outline),
                const SizedBox(width: 8),
                _buildTabChip('Health Feed', Icons.health_and_safety_outlined),
              ],
            ),
          ),

          if (_selectedTab == 'Community') ...[
            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _buildFilterChip('Hot', Icons.local_fire_department),
                  const SizedBox(width: 8),
                  _buildFilterChip('Local', Icons.location_on_outlined),
                  const SizedBox(width: 8),
                  _buildFilterChip('Official', Icons.verified_outlined),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  final posts = snapshot.data!.docs;
                  if (posts.isEmpty) return const Center(child: Text('No updates yet. Be the first to broadcast!'));
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: posts.length,
                    itemBuilder: (context, index) => _buildPostCard(posts[index]),
                  );
                },
              ),
            ),
          ] else ...[
            // Health Feed
            Expanded(
              child: Container(
                color: const Color(0xFFF5F5F7),
                child: ListView.builder(
                  itemCount: mockHealthPosts.length,
                  itemBuilder: (context, index) => HealthPostCard(post: mockHealthPosts[index]),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getStream() {
    final collection = FirebaseFirestore.instance.collection('feed_posts');
    
    if (_selectedFilter == 'Official') {
      return collection.where('isOfficial', isEqualTo: true).orderBy('timestamp', descending: true).snapshots();
    } else if (_selectedFilter == 'Hot') {
      return collection.orderBy('upvoteCount', descending: true).snapshots();
    } else {
      return collection.orderBy('timestamp', descending: true).snapshots();
    }
  }

  Widget _buildTabChip(String label, IconData icon) {
    final bool isSel = _selectedTab == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? primary : surfaceContainerHighest,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSel ? onPrimary : onSurfaceVariant),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSel ? onPrimary : onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final bool isSel = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? primaryContainer : surfaceContainerHighest,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSel ? onPrimaryContainer : onSurfaceVariant),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSel ? onPrimaryContainer : onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    final List upvotes = data['upvotes'] ?? [];
    final List downvotes = data['downvotes'] ?? [];
    final bool isUpvoted = upvotes.contains(uid);
    final bool isDownvoted = downvotes.contains(uid);
    final bool isOfficial = data['isOfficial'] ?? false;
    final String imageUrl = data['imageUrl'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outlineVariant),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: isOfficial ? primaryFixed : surfaceVariant,
                  child: Icon(isOfficial ? Icons.verified : Icons.person, size: 14, color: isOfficial ? primary : outline),
                ),
                const SizedBox(width: 8),
                Text(data['authorName'] ?? 'Citizen', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                if (isOfficial) ...[
                  const SizedBox(width: 4),
                  const Text('• OFFICIAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primary)),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(data['category']),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    (data['category'] ?? 'General').toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              data['content'] ?? '',
              style: const TextStyle(fontSize: 16, color: onSurface, height: 1.4),
            ),
          ),
          if (imageUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl.startsWith('http') 
                  ? Image.network(imageUrl, width: double.infinity, height: 200, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink())
                  : (kIsWeb 
                      ? Image.network(imageUrl, width: double.infinity, height: 200, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink())
                      : Image.file(File(imageUrl), width: double.infinity, height: 200, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink())
                    ),
              ),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF7F9FF),
              border: Border(top: BorderSide(color: surfaceVariant)),
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(color: surfaceContainerHighest, borderRadius: BorderRadius.circular(100)),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_upward_rounded, size: 20, color: isUpvoted ? Colors.orange : outline),
                        onPressed: () => _handleVote(doc.id, true, isUpvoted, isDownvoted, upvotes, downvotes),
                      ),
                      Text('${upvotes.length - downvotes.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(Icons.arrow_downward_rounded, size: 20, color: isDownvoted ? Colors.blue : outline),
                        onPressed: () => _handleVote(doc.id, false, isUpvoted, isDownvoted, upvotes, downvotes),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chat_bubble_outline, size: 20, color: outline),
                const SizedBox(width: 8),
                const Text('Discuss', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: outline)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'Hazard': return Colors.redAccent;
      case 'Traffic': return Colors.orangeAccent;
      case 'Medical Info': return Colors.blueAccent;
      default: return outline;
    }
  }

  Future<void> _handleVote(String postId, bool isUpvote, bool alreadyUpvoted, bool alreadyDownvoted, List upvotes, List downvotes) async {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    final docRef = FirebaseFirestore.instance.collection('feed_posts').doc(postId);

    if (isUpvote) {
      if (alreadyUpvoted) {
        await docRef.update({
          'upvotes': FieldValue.arrayRemove([uid]),
          'upvoteCount': FieldValue.increment(-1),
        });
      } else {
        await docRef.update({
          'upvotes': FieldValue.arrayUnion([uid]),
          'upvoteCount': FieldValue.increment(1),
          if (alreadyDownvoted) 'downvotes': FieldValue.arrayRemove([uid]),
        });
      }
    } else {
      if (alreadyDownvoted) {
        await docRef.update({
          'downvotes': FieldValue.arrayRemove([uid]),
        });
      } else {
        await docRef.update({
          'downvotes': FieldValue.arrayUnion([uid]),
          if (alreadyUpvoted) 'upvotes': FieldValue.arrayRemove([uid]),
          if (alreadyUpvoted) 'upvoteCount': FieldValue.increment(-1),
        });
      }
    }
  }
}

// ─── Health Feed Data ───────────────────────────────────────────────────────

class HealthPost {
  final String id, author, community, timeAgo, title, description, imageUrl;
  final int upvotes, commentCount;
  const HealthPost({
    required this.id, required this.author, required this.community,
    required this.timeAgo, required this.title, required this.description,
    required this.imageUrl, required this.upvotes, required this.commentCount,
  });
}

const List<HealthPost> mockHealthPosts = [
  HealthPost(
    id: '1', author: 'u/DrSarah', community: 'r/ArognaNutrition', timeAgo: '2h ago',
    title: '5 Superfoods to Boost Your Immune System This Season',
    description: 'Including leafy greens, citrus fruits, and nuts in your daily diet can provide essential vitamins. I particularly recommend adding spinach and citrus to every meal.',
    imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=400',
    upvotes: 215, commentCount: 45,
  ),
  HealthPost(
    id: '2', author: 'u/MentalHealthAware', community: 'r/ArognaMentalHealth', timeAgo: '4h ago',
    title: 'Simple Mindfulness Techniques for Managing Work Stress',
    description: 'A brief guide on integrating micro-meditation into your busy schedule. Even 5 minutes of focused breathing can dramatically reduce cortisol levels.',
    imageUrl: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?q=80&w=400',
    upvotes: 312, commentCount: 92,
  ),
  HealthPost(
    id: '3', author: 'u/CardioCoach', community: 'r/ArognaFitness', timeAgo: '6h ago',
    title: 'Cardio vs Strength Training: Which Burns More Fat?',
    description: 'The short answer: both, combined. Here is how to structure your week for maximum fat loss while preserving lean muscle mass for long-term health.',
    imageUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?q=80&w=400',
    upvotes: 189, commentCount: 67,
  ),
  HealthPost(
    id: '4', author: 'u/HydrationHub', community: 'r/ArognaWellness', timeAgo: '8h ago',
    title: '7 Warning Signs You Are Chronically Dehydrated',
    description: 'Dark urine, persistent headaches, and brain fog are all classic signs. Most adults are mildly dehydrated throughout the day without realizing it.',
    imageUrl: 'https://images.unsplash.com/photo-1523362628745-0c100150b504?q=80&w=400',
    upvotes: 143, commentCount: 38,
  ),
  HealthPost(
    id: '5', author: 'u/PosturePhysio', community: 'r/ArognaPosture', timeAgo: '10h ago',
    title: 'The 3-Minute Desk Posture Reset You Should Do Every Hour',
    description: 'Sitting for long periods compresses your spine and weakens your glutes. This simple 3-minute routine counters the damage of a full workday at your desk.',
    imageUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?q=80&w=400',
    upvotes: 276, commentCount: 54,
  ),
];

class HealthPostCard extends StatelessWidget {
  final HealthPost post;
  const HealthPostCard({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFD8E2FF),
                  child: Text(post.author[2].toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0059BB))),
                ),
                const SizedBox(width: 8),
                Text(post.community, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0059BB))),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('by ${post.author} • ${post.timeAgo}',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(post.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                post.imageUrl,
                height: 180, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: const Color(0xFFEBEEF3),
                  child: const Center(child: Icon(Icons.image_outlined, color: Colors.grey, size: 40)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(post.description, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.arrow_upward_rounded, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${post.upvotes}', style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_downward_rounded, size: 20, color: Colors.grey[600]),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.mode_comment_outlined, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${post.commentCount} Comments', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
                Icon(Icons.share_outlined, size: 20, color: Colors.grey[600]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
