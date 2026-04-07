import 'package:flutter/material.dart';

class WhatWeNeedPage extends StatelessWidget {
  const WhatWeNeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAF6FB),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "What We Need",
          style: TextStyle(
            color: Color(0xFF163B6D),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        child: Column(
          children: const [
            RequirementPosterCard(
              imagePath: "assets/passport.webp",
              title: "1. Personal Identification",
              bulletPoints: [
                "Passport: Required for every single person in the vehicle.",
                "App Tip: Mention that the passport must have at least 6 months validity remaining.",
                "Driver’s License: A valid Malaysian license is accepted in Thailand.",
              ],
            ),
            SizedBox(height: 20),

            RequirementPosterCard(
              imagePath: "assets/vehicledoc.jpeg",
              title: "2. Vehicle Documents",
              bulletPoints: [
                "Vehicle Registration Card (Geran): A clear copy or original (for scanning).",
                "Compulsory Insurance (CI): Users need this to generate the TM2 (Information of Conveyance) and TM3 (Passenger List) forms.",
              ],
            ),
            SizedBox(height: 20),

            RequirementPosterCard(
              imagePath: "assets/authorize.jpg",
              title: "3. Authorization (If the Owner is NOT Present)",
              bulletPoints: [
                "If the person driving is not the owner listed in the Geran, the app must ask for:",
                "Authorization Letter: A signed letter from the owner giving permission to take the car into Thailand.",
                "Owner’s IC (Copy): A copy of the owner’s Identity Card to verify the signature on the letter.",
              ],
            ),
            SizedBox(height: 20),

            RequirementPosterCard(
              imagePath: "assets/forms.jpg",
              title: "4. Customs & Immigration Forms",
              bulletPoints: [
                "Your app will help generate these, but users still need the required info from the above documents.",
                "TM2 & TM3 Forms: Information about the vehicle and the list of passengers.",
                "Arrival/Departure Card (White Card/TM6): Usually filled at the border, but the app can store the details.",
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RequirementPosterCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final List<String> bulletPoints;

  const RequirementPosterCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.bulletPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF169BFF),
          width: 2,
        ),
        color: const Color(0xFF5B2C2C),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          /// TOP IMAGE
          SizedBox(
            width: double.infinity,
            height: 200,
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
          ),

          /// BOTTOM WHITE TEXT AREA
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(26),
                bottomRight: Radius.circular(26),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// TITLE
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 14),

                /// BULLETS
                ...bulletPoints.map(
                  (point) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 3),
                          child: Icon(
                            Icons.circle,
                            size: 8,
                            color: Color(0xFF163B6D),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            point,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}