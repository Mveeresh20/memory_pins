import 'package:eventspot/lib_module.dart';

String contactInfoMailId = "contactus@info.com";

markEualStatusInLocal({bool agree = true}) {
  SharedPref.pref.setBool("eula", agree);
}

bool isEualAgreementAgreedFromLocal() {
  return SharedPref.pref.getBool(
        "eula",
      ) ??
      false;
}


showEulaAgreementDialog(BuildContext context,
    {bool withButtons = true, ValueChanged<bool>? onAgreed}) async {
  showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: AppColors.scaffoldBackground,
          child: SingleChildScrollView(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    " End User License Agreement ",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(eulaPoints.length, (i) {
                    EulaPointsModel point = eulaPoints[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          point.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 50,
                        ),
                        if (point.description.isNotEmpty)
                          Text(
                            point.description,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                            maxLines: 50,
                          ),
                        if (point.points.isNotEmpty)
                          ...List.generate(point.points.length, (j) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(width: 12),
                                const Padding(
                                  padding: EdgeInsets.all(4.0),
                                  child: CircleAvatar(
                                    backgroundColor: Colors.white,
                                    radius: 4,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    point.points[j],
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.normal,
                                    ),
                                    maxLines: 500,
                                  ),
                                ),
                              ],
                            );
                          }),
                        Divider(
                          color: Colors.grey.withAlpha(60),
                        )
                      ],
                    );
                  }),
                  if (withButtons)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            side: const BorderSide(color: Colors.black),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("Cancel"),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            if (onAgreed != null) {
                              onAgreed(true);
                              Navigator.pop(context);
                            }
                          },
                          child: const Text("Agree"),
                        ),
                      ],
                    )
                ],
              ),
            ),
          ),
        );
      });
}

class EulaPointsModel {
  String title;
  String description;
  List<String> points;
  EulaPointsModel({
    required this.title,
    required this.description,
    required this.points,
  });
}

List<EulaPointsModel> eulaPoints = [
  EulaPointsModel(
    title: 'License Grant',
    description:
        'We grant you a limited, non-exclusive, non-transferable license to use this app for personal, non-commercial purposes.',
    points: [
      'You may not modify, distribute, or reverse-engineer the app.',
    ],
  ),
  EulaPointsModel(
    title: 'User Responsibilities',
    description: 'You agree to:',
    points: [
      'Use the app legally and in accordance with all applicable laws.',
      'Keep your account credentials secure.',
      'Respect others and avoid sharing harmful, abusive, or inappropriate content.',
    ],
  ),
  EulaPointsModel(
    title: 'User-Generated Content (Events & Comments)',
    description:
        'This app allows users to create events and comment on them. You are solely responsible for the content you create.',
    points: [
      'Do not post content that is abusive, offensive, discriminatory, or violates the rights of others.',
      'Do not share spam, misleading, or false information.',
      'We reserve the right to moderate or remove any content that violates our guidelines or receives abuse reports.',
      'Violation of these terms may result in suspension or removal of your account.',
    ],
  ),
  EulaPointsModel(
    title: 'Reporting Abusive Content',
    description:
        'Users can report comments or content that appear abusive, harmful, or inappropriate.',
    points: [
      'All reports are reviewed by the moderation team.',
      'We may remove the reported content and take action against the offending user.',
      'Repeated violations can lead to permanent account bans.',
    ],
  ),
  EulaPointsModel(
    title: 'Blocking Users',
    description:
        'Users can block other users to avoid unwanted interactions or content.',
    points: [
      'Blocked users cannot comment or interact with your events.',
      'Neither user will be notified when a block occurs.',
      'Mutual blocking prevents both users from seeing each other’s content.',
    ],
  ),
  EulaPointsModel(
    title: 'Moderation and Admin Rights',
    description:
        'We reserve the right to moderate user content to ensure community safety.',
    points: [
      'Inappropriate or offensive content may be removed at any time.',
      'Users violating community rules may be suspended or banned.',
    ],
  ),
  EulaPointsModel(
    title: 'Usage Restrictions',
    description: 'You agree not to:',
    points: [
      'Copy, alter, or redistribute the app’s code or content.',
      'Decompile or reverse-engineer the application.',
      'Sell, rent, or license access to the app.',
      'Post content that infringes on copyrights or violates privacy rights.',
    ],
  ),
  EulaPointsModel(
    title: 'Intellectual Property',
    description:
        'All app content, UI/UX design, and intellectual property belong to the company.',
    points: [
      'Using the app does not grant you ownership of any part of its design, branding, or content.',
    ],
  ),
  EulaPointsModel(
    title: 'Termination',
    description:
        'We reserve the right to terminate user access at our discretion.',
    points: [
      'Upon termination, you must stop using the app immediately.',
    ],
  ),
  EulaPointsModel(
    title: 'Limitation of Liability',
    description:
        'We are not liable for damages resulting from use of the app or user-generated content.',
    points: [
      'Use the app at your own risk.',
      'The app is provided "as is" without warranties.',
    ],
  ),
  EulaPointsModel(
    title: 'Updates and Amendments',
    description:
        'We may update this EULA at any time. Continued use of the app means you accept the revised terms.',
    points: [],
  ),
  EulaPointsModel(
    title: 'Contact Us',
    description:
        'If you have questions or need to report an issue, contact us at: $contactInfoMailId',
    points: [],
  ),
];
