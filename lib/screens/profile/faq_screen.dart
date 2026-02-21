import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  final List<Map<String, String>> _faqs = const [
    {
      'question': 'How do I create a help request?',
      'answer': 'Tap the "+" button at the bottom of the screen. Fill in the details like title, description, and location, then tap "Submit Request".',
    },
    {
      'question': 'Is my personal information safe?',
      'answer': 'Yes. We only share necessary details with helpers you accept. We do not share your exact address publicly.',
    },
    {
      'question': 'How do matches work?',
      'answer': 'Our AI analyzes your request and suggests helpers based on their skills, location, and rating. The "Match Score" shows how well a helper fits your needs.',
    },
    {
      'question': 'Can I chat with helpers before accepting?',
      'answer': 'No. For safety, chat is only enabled after you accept a helper\'s application.',
    },
    {
      'question': 'How do I become a helper?',
      'answer': 'Go to your Profile, tap "Edit Profile", and add skills that match your expertise. You will then appear in search results for relevant requests.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FAQ', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _faqs.length,
        itemBuilder: (context, index) {
          final faq = _faqs[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              title: Text(
                faq['question']!,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    faq['answer']!,
                    style: GoogleFonts.poppins(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
