import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/about_controller.dart';

class AboutView extends GetView<AboutController> {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        title: Text(
          'Universa Academy',
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A2E),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'عن ',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: 'Universa Academy',
                          style: GoogleFonts.cairo(
                            color: const Color(0xFFBB86FC),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'منصة تعليمية متميزة تجمع بين خبرة أساتذة الجامعات وتقنيات التعلم الحديثة',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Mission Section
                  _buildSectionCard(
                    title: 'رسالتنا',
                    content: 'تتمثل رسالتنا في Universa Academy في توفير تعليم عالي الجودة يكون متاحًا للجميع بغض النظر عن الموقع الجغرافي أو الظروف الشخصية. نسعى لتمكين الطلاب من خلال منحهم فرصة الوصول إلى محتوى تعليمي متميز يقدمه نخبة من الأساتذة المتخصصين.',
                    icon: Icons.rocket_launch_rounded,
                    color: Colors.blueAccent,
                    isLeftIcon: true,
                  ),
                  const SizedBox(height: 20),

                  // Vision Section
                  _buildSectionCard(
                    title: 'رؤيتنا',
                    content: 'نتطلع في Universa Academy إلى أن نكون المنصة التعليمية الرائدة في العالم العربي، التي تجسر الفجوة بين التعليم التقليدي والتعلم الرقمي، وتوفر تجربة تعليمية متكاملة تجمع بين جودة المحتوى وسهولة الوصول.',
                    icon: Icons.remove_red_eye_rounded,
                    color: Colors.tealAccent,
                    isLeftIcon: false,
                  ),
                  const SizedBox(height: 40),

                  // Values Section
                  _buildSectionTitle('قيمنا'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildValueCard('الأمان', Icons.security, Colors.purpleAccent)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildValueCard('الشمولية', Icons.groups_rounded, Colors.cyanAccent)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildValueCard('الجودة', Icons.verified_rounded, Colors.purpleAccent)),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Team Section
                  _buildSectionTitle('فريق العمل'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTeamCard(
                          'د. محمد هشام',
                          'مدير المحتوى التعليمي',
                          'طبيب امتياز',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTeamCard(
                          'د. أحمد عبد الناصر',
                          'الرئيس التنفيذي',
                          'طبيب امتياز',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Stats Section
                  _buildSectionTitle('Universa Academy بالأرقام'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('+95', 'نسبة رضا الطلاب'),
                        _buildStatItem('+30', 'أستاذ جامعي'),
                        _buildStatItem('+50', 'دورة تعليمية'),
                        _buildStatItem('+1000', 'طالب مسجل'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // FAQ Section
                  _buildSectionTitle('الأسئلة الشائعة'),
                  const SizedBox(height: 16),
                  _buildFAQItem('كيف يمكنني التسجيل في المنصة؟', 'يمكنك التسجيل بسهولة من خلال النقر على "حساب جديد" في الصفحة الرئيسية، ثم ملء البيانات المطلوبة وإنشاء حساب جديد. بعد ذلك، يمكنك تصفح الدورات المتاحة والتسجيل فيها.'),
                  _buildFAQItem('هل الدورات معتمدة؟', 'نعم، جميع الدورات المقدمة على منصة Universa Academy معتمدة ويتم تقديمها من قبل أساتذة جامعيين متخصصين. نحن نحرص على توفير محتوى تعليمي يتوافق مع المعايير الأكاديمية العالمية.'),
                  _buildFAQItem('كيف يمكنني الوصول إلى المحتوى بعد التسجيل؟', 'بعد التسجيل في أي دورة، يمكنك الوصول إلى المحتوى من خلال الصفحة الرئيسية في حسابك الشخصي. يمكنك مشاهدة المحاضرات، وتنزيل المواد التعليمية، والمشاركة في الاختبارات من خلال هذه الصفحة.'),
                  _buildFAQItem('هل يمكنني الوصول إلى المحتوى من أي جهاز؟', 'لضمان أمان المحتوى وحماية حقوق الملكية الفكرية، يمكنك الوصول إلى المحتوى من خلال جهاز واحد فقط يتم توثيقه عند التسجيل. هذا يساعدنا في منع مشاركة المحتوى بشكل غير مصرح به.'),
                  const SizedBox(height: 40),

                  // Contact Banner
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'تواصل معنا',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'لديك استفسار أو ترغب في معرفة المزيد عن خدماتنا؟ فريقنا جاهز للرد على جميع استفساراتك',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            Get.defaultDialog(
                              title: 'الدعم الفني',
                              titleStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white),
                              backgroundColor: const Color(0xFF1A1A2E),
                              contentPadding: const EdgeInsets.all(20),
                              content: Text(
                                'للتواصل مع الدعم الفني أو الاستفسارات البرمجية والأكاديمية، يمكنك مراسلتنا عبر البريد الإلكتروني:\n\nsupport@universa-academy.site',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14),
                              ),
                              confirm: TextButton(
                                onPressed: () => Get.back(),
                                child: Text('حسناً', style: GoogleFonts.cairo(color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
                              ),
                            );
                          },
                          icon: const Icon(Icons.email_outlined),
                          label: Text(
                            'الدعم الفني',
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF4A148C),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Center(
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFBB86FC), width: 2)),
        ),
        child: Text(
          title,
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
    required bool isLeftIcon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              // Optional: Icon could go here if needed, but keeping it simple for now
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isLeftIcon) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Text(
                  content,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.cairo(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
              if (!isLeftIcon) ...[
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueCard(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Short description could go here if available
        ],
      ),
    );
  }

  Widget _buildTeamCard(String name, String role, String subRole) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_outline, color: Colors.white54, size: 40),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            role,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              color: const Color(0xFFBB86FC),
              fontSize: 12,
            ),
          ),
          Text(
            subRole,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              color: Colors.white54,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.cairo(
            color: const Color(0xFF00E5FF),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.cairo(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Theme(
        data: Theme.of(Get.context!).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconColor: Colors.white70,
          collapsedIconColor: Colors.white54,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                textAlign: TextAlign.right,
                style: GoogleFonts.cairo(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
