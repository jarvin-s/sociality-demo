import 'package:flutter/material.dart';

// ignore_for_file: avoid_print
// this line ignores the warning for avoiding print in production code,
// see https://stackoverflow.com/questions/69531248/avoid-print-calls-in-production-code-documentation

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD89B6A),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Logo
            Image.asset(
              'assets/images/logo.png',
              height: 40,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63),
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            const Text(
              'Sociality',
              style: TextStyle(
                color: Color(0xFF2C3E7E),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // "Aanbevolen" Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C3E7E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Aanbevolen',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Story Cards
                      _buildStoryCard(
                        context,
                        title: '1ST STORY\nHET SKATEPARK',
                        imageUrl: 'assets/images/skatepark_story.png',
                        onTap: () {
                          _showStoryOptions(context, 'HET SKATEPARK');
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Placeholder cards (for future stories)
                      _buildPlaceholderCard(context),
                      
                      const SizedBox(height: 16),
                      
                      _buildPlaceholderCard(context),
                      
                      const SizedBox(height: 80), // Space for fixed bottom bar
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // Fixed bottom bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: const BoxDecoration(
          color: Color(0xFFD89B6A),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // Start Button (Host)
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      _showHostOptions(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.play_arrow, color: Colors.white, size: 22),
                        SizedBox(width: 6),
                        Text(
                          'Start',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Deelnemen Button (Join)
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      _showJoinOptions(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.groups, color: Color(0xFF2C3E7E), size: 22),
                        SizedBox(width: 6),
                        Text(
                          'Deelnemen',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E7E),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // QR Scan Button
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8D5C4),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/join-qr');
                  },
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.qr_code_scanner,
                    color: Color(0xFF2C3E7E),
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryCard(
    BuildContext context, {
    required String title,
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: AssetImage(imageUrl),
            fit: BoxFit.cover,
            onError: (error, stackTrace) {},
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Dark overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
            
            // Title
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
            ),
            
            // Play button
            Positioned(
              right: 16,
              bottom: 16,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderCard(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Placeholder content
          Center(
            child: Icon(
              Icons.image_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          
          // Play button
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE91E63).withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStoryOptions(BuildContext context, String storyTitle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext modalContext) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              storyTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E7E),
              ),
            ),
            const SizedBox(height: 24),
            
            // Host option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.games, color: Colors.white),
              ),
              title: const Text(
                'Spel hosten',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Start een nieuw spel als host'),
              onTap: () {
                print('Spel hosten tapped');
                Navigator.pop(modalContext); // Close modal
                print('Modal closed, calling _createGame');
                _createGame(context, storyTitle); // Use parent context
              },
            ),
            
            const Divider(),
            
            // Join option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C3E7E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.login, color: Colors.white),
              ),
              title: const Text(
                'Deelnemen aan spel',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Voer een PIN in om deel te nemen'),
              onTap: () {
                print('Deelnemen aan spel tapped');
                Navigator.pop(modalContext); // Close modal
                print('Modal closed, navigating to /join-pin');
                Navigator.pushNamed(context, '/join-pin'); // Use parent context
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHostOptions(BuildContext context) {
    // Show available stories to host
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext modalContext) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Kies een verhaal om te hosten',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E7E),
              ),
            ),
            const SizedBox(height: 24),
            
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.skateboarding, color: Colors.white),
              ),
              title: const Text(
                'HET SKATEPARK',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('1e verhaal'),
              onTap: () {
                Navigator.pop(modalContext); // Close modal
                _createGame(context, 'HET SKATEPARK'); // Use parent context
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext modalContext) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Deelnemen aan spel',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E7E),
              ),
            ),
            const SizedBox(height: 24),
            
            // PIN option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.pin, color: Colors.white),
              ),
              title: const Text(
                'PIN invoeren',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Voer een 4-cijferige PIN in'),
              onTap: () {
                Navigator.pop(modalContext); // Close modal
                Navigator.pushNamed(context, '/join-pin'); // Use parent context
              },
            ),
            
            const Divider(),
            
            // QR option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C3E7E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.qr_code_scanner, color: Colors.white),
              ),
              title: const Text(
                'QR-code scannen',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Scan de QR-code van de host'),
              onTap: () {
                Navigator.pop(modalContext); // Close modal
                Navigator.pushNamed(context, '/join-qr'); // Use parent context
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createGame(BuildContext context, String storyTitle) {
    print('Creating game with story: $storyTitle');
    
    // Navigate to host name entry screen via route
    Navigator.pushNamed(
      context,
      '/host-name-entry',
      arguments: {
        'storyTitle': storyTitle,
      },
    ).then((value) {
      print('Returned from host name entry');
    }).catchError((error) {
      print('Navigation error: $error');
    });
  }
}