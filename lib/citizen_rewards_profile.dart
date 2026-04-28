import 'package:flutter/material.dart';

class CitizenRewardsProfile extends StatelessWidget {
  const CitizenRewardsProfile({Key? key}) : super(key: key);

  // Design System Colors from Stitch
  static const Color background = Color(0xFFF7F9FF);
  static const Color onBackground = Color(0xFF181C20);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF1F4F9);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E8);
  static const Color surfaceVariant = Color(0xFFE0E3E8);
  static const Color onSurface = Color(0xFF181C20);
  static const Color onSurfaceVariant = Color(0xFF414754);
  static const Color primary = Color(0xFF0059BB);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF0070EA);
  static const Color onPrimaryContainer = Color(0xFFFEFCFF);
  static const Color primaryFixedDim = Color(0xFFADC7FF);
  static const Color primaryFixed = Color(0xFFD8E2FF);
  static const Color outline = Color(0xFF717786);
  static const Color outlineVariant = Color(0xFFC1C6D7);
  static const Color tertiary = Color(0xFF545D65);
  static const Color tertiaryContainer = Color(0xFF6D767E);
  static const Color onTertiaryContainer = Color(0xFFFCFCFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: surfaceContainerLowest,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(bottom: BorderSide(color: surfaceVariant, width: 1)),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuDbtKSo7-1ixOUBZ3K9HEaUUp7gZIwvzcBzeagcmz51tTXchzyfKljLsiNBf8ERWiTRujNdYgH5agB_3xwiWCfUbnt74N2nznSwlVU8adgGukQAyyT84lYXlUVPWBFsH2c9KSH_px6rufm54WV2QDdF1Kzqa3oGQL3We0nAqjn9cOMrMlXltqHbyjXsa_Z4KYVFFw3bBmz0-hciwd4D7CLp64bW_r8rZbXJSpn6dh_TS3h_NSA-ItuKYNd4GdOjdOh0xJWDKLeV3_w',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.person, color: onSurfaceVariant, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Arogna',
              style: TextStyle(
                color: primary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: outline),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 768),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Text
                const Text(
                  'Rewards & Recognition',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: onSurface,
                    fontFamily: 'Inter',
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Track your operational readiness and peer standing.',
                  style: TextStyle(
                    fontSize: 16,
                    color: onSurfaceVariant,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 32),

                // Top Card: User Points & Badge
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: primaryContainer.withOpacity(0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Decorative background glow
                      Positioned(
                        top: -64,
                        right: -32,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                          child: BackdropFilter(
                            filter: ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
                            child: Container(),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CURRENT STATUS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: onPrimaryContainer.withOpacity(0.8),
                                  letterSpacing: 1.5,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                '1250',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: onPrimaryContainer,
                                  fontFamily: 'Inter',
                                  letterSpacing: -1.0,
                                ),
                              ),
                              const Text(
                                'Guardian',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: onPrimaryContainer,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Column(
                              children: const [
                                Icon(Icons.military_tech, color: Colors.white, size: 64),
                                SizedBox(height: 8),
                                Text(
                                  'Savior Badge',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Leaderboard List
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    'Top Responders',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      children: [
                        _buildLeaderboardItem(
                          rank: 1,
                          name: 'Dr. Sarah Miller',
                          role: 'Chief Medical Officer',
                          points: '2,450',
                          avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDysnwtbP2JNMp9bsmt5KM8e6O2s0l631uZz4InGBWpQM5jmqJ9VINNla4F6xBVkum7hGD2lokkEc45rE4K73BJwJ_1nSiiBcwp84l_QkhGjOhmuWJSl8Au61rYc7T4vBgRdoR07q9_mPdUUXk0mt9x2dbQJRNQvcZtzfneIadOFvRIdBIG3UBFkcOHH6eszm9a6RH6THx-SpTqY6samGbB8x_LWny9CGDNh2NNkT1MxhyKg2bBYA3zEOU5PePQrnSPz2puznOdLck',
                          rankColor: primary,
                          rankTextColor: onPrimary,
                          bgColor: primary.withOpacity(0.05),
                          pointsColor: primary,
                        ),
                        const Divider(height: 1, color: surfaceVariant),
                        _buildLeaderboardItem(
                          rank: 2,
                          name: 'Paramedic Davis',
                          role: 'Field Unit Alpha',
                          points: '1,980',
                          avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuASaeTIc9naEM8Wt4pc6JzxtzJ7exq4kz6nPBKcLvI2hoIzbm9yD-xyQhFBMZXExfMbuDcXAy8jZjYpqY_Boqe7jDRlQ88tYYGxh94R3FcM5JOnriOGuyhUIwOVUWiOm7BReg-zlP-bGBGfHKZL04FKXNxny3mmNiy4GmqHQG1kNY0s9OsuqTVUQAkwsocqJJWo0PgJqCNbY5p2MH9VO16-UenYqqxAOT2gfs5iUspV1Jvrjd3ZCCwsRcxAOSmhhnUWnSdCGXGgPyc',
                          rankColor: outline,
                          rankTextColor: Colors.white,
                          bgColor: surfaceContainerLow,
                          pointsColor: outline,
                        ),
                        const Divider(height: 1, color: surfaceVariant),
                        _buildLeaderboardItem(
                          rank: 3,
                          name: 'Nurse Patel',
                          role: 'Trauma Ward',
                          points: '1,820',
                          avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAsIsG72NsaMtmcQb34wdC3XniGqBeq9wFwQsX_b4wGytqhb_qe7GYMMgjBsUsOjX8LsWxjQaN4ZBXh3vX_h66a1r1Rl-FYw2_kjV7O7F05ydvX6SZxTsg_w6KCa-Vjw1yEFrTlVqMWkAl_gc3FrLfR4ga9NsbvuApC4BAx3RgfC20BEWQRZsnSbCM0tzu-r85EcyjLEJdy_tIZkZnIMx3AMy4t1ubGfGHWKp3V3vdc2L4gElwV8iNkgFTjmbK5OGvZ_L8iWDD_GV8',
                          rankColor: tertiaryContainer,
                          rankTextColor: onTertiaryContainer,
                          bgColor: surfaceContainerLow,
                          pointsColor: tertiary,
                        ),
                        const Divider(height: 1, color: surfaceVariant),
                        _buildLeaderboardItem(
                          rank: 4,
                          name: 'Dr. Reynolds',
                          role: 'General Practice',
                          points: '1,500',
                          avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuD28qJTD8rAMpvjilGJ9jlUu7Uiexh7doFoG2keWyMYG6whuqrFAUst1qOhbK1fXdhRUuhdn23yzz4HfBgsw8kf0Jm3wvJiEJXPGdwl6oxqyy2FwjnvCX4kHB3Wt8Aj2Q45eA2c049OQc9BrmD8PgF0rZ3NDT1-vF1OrACaBWCVCmjUdYkBrxBKA1jchaIhvupp5cga2KisF4TlRG__wFDB3v9sxBbQZUV6AmyyOI6vz9op6L0e7DpFOV4wpx1xpLhDmXH6Vz78GGA',
                          rankColor: Colors.transparent,
                          rankTextColor: onSurfaceVariant,
                          bgColor: Colors.transparent,
                          pointsColor: onSurfaceVariant,
                          avatarBorderColor: Colors.transparent,
                        ),
                        const Divider(height: 1, color: surfaceVariant),
                        _buildLeaderboardItem(
                          rank: 5,
                          name: 'You',
                          role: 'Guardian',
                          points: '1,250',
                          avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCQLJdmXlKvl93cP4fiBuMq8kbvn5FtduL346v21QfpjuUsYEfEk2e-dceWDxaCNJZjHNITn4_JgktkXBDIZhVLhE2xqm2DgJTW4ffhueh36BWyg0fx6_fdWjBV44n1tFfy7Er2bPYJR9cLGQna9_Z5zGBhPgZLeC1jAj0_Py3l6K7RnyjYtxH23eWlmRE4xLP8LGeoN76OmV4uVzIx6KYJZle-_u6bynU2ci1MajTztqTMFnPFRDUxhuRFMha2l7OJtTprVGDpiPE',
                          rankColor: Colors.transparent,
                          rankTextColor: primary,
                          bgColor: primaryFixed.withOpacity(0.3),
                          pointsColor: primary,
                          nameColor: primary,
                          avatarBorderColor: primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardItem({
    required int rank,
    required String name,
    required String role,
    required String points,
    required String avatarUrl,
    required Color rankColor,
    required Color rankTextColor,
    required Color bgColor,
    required Color pointsColor,
    Color nameColor = onSurface,
    Color? avatarBorderColor,
  }) {
    return Container(
      color: bgColor,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rankColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: rankTextColor,
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: avatarBorderColor ?? rankColor,
                width: 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(Icons.person, color: outlineVariant),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: nameColor,
                    fontFamily: 'Inter',
                  ),
                ),
                Text(
                  role,
                  style: const TextStyle(
                    fontSize: 14,
                    color: onSurfaceVariant,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                points,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: pointsColor,
                  fontFamily: 'Inter',
                ),
              ),
              if (rank <= 3)
                Text(
                  'PTS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: pointsColor,
                    letterSpacing: 0.5,
                    fontFamily: 'Inter',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
