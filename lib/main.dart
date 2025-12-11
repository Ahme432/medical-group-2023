import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

// TODO: Replace with your actual Firebase Options
// You can get this by running: flutterfire configure
// Or by creating a project in Firebase Console > Project Settings > General > Your apps > Web > SDK Setup
const FirebaseOptions defaultFirebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyBPR8kEvHIPKVtbw7HX2UKYlTx7-8gXe6k",
  appId: "1:947530553430:web:3b399b52247ff5d9aa43f7",
  messagingSenderId: "947530553430",
  projectId: "medical-group-2023",
  authDomain: "medical-group-2023.firebaseapp.com",
  storageBucket: "medical-group-2023.firebasestorage.app",
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: defaultFirebaseOptions);
  } catch (e) {
    print("Firebase init error (Expected if config is missing): $e");
  }
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'استمارة الحضور - المجموعة الطبية 2023',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Segoe UI', // Good fallback for Windows, usually available
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9C27B0), // Purple/Violet from logo
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const AttendanceScreen(),
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
    );
  }
}

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Dynamic Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4A148C), // Purple 900
                  Color(0xFF7B1FA2), // Purple 700
                  Color(0xFF9C27B0), // Purple 500
                  Color(0xFFCE93D8), // Purple 200
                ],
              ),
            ),
          ),
          // Decorative Circles (for glass effect depth)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),

          // 2. Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Wrap(
                  spacing: 32,
                  runSpacing: 32,
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // A. Statistics Column (Left Side on large screens)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: const _StatsDashboard(),
                    ),

                    // B. Registration Form (Right Side)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: _GlassCard(
                        padding: const EdgeInsets.all(40),
                        child: const AttendanceForm(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsDashboard extends StatelessWidget {
  const _StatsDashboard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Listen to the 'attendees' collection
      stream: FirebaseFirestore.instance.collection('attendees').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            'Error: ${snapshot.error}',
            style: const TextStyle(color: Colors.redAccent),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading or mock data while loading
          return const CircularProgressIndicator(color: Colors.white);
        }

        final docs = snapshot.data!.docs;

        // Calculate total including guests
        // Assumes 'guest_count' field exists in doc, default to 0 if not.
        int calculatedTotal = 0;
        final Map<String, int> govCounts = {};

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final gov = data['governorate'] as String? ?? 'غير محدد';
          final guests = (data['guest_count'] as num?)?.toInt() ?? 0;

          calculatedTotal += (1 + guests); // Self + Guests
          govCounts[gov] =
              (govCounts[gov] ?? 0) + (1 + guests); // Count people per gov
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GlassCard(
              child: Column(
                children: [
                  const Text(
                    'عدد المسجلين الكلي',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 20, // Slightly larger
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$calculatedTotal',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 64, // Larger number
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black26,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'طالب من المجموعة الطبية',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'توزيع المحافظات',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sorted Gov Entries
                  ...(() {
                    final entries =
                        govCounts.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value));
                    return entries.take(5).map((e) {
                      final percentage =
                          calculatedTotal == 0
                              ? 0.0
                              : e.value / calculatedTotal;
                      // Note: Percentage base is debatable here.
                      // Using per-entry count for gov share is cleaner for "where are people from"
                      // regardless of how many guests they brought.

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  e.key,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${e.value}', // Show actual count of people
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: percentage,
                              backgroundColor: Colors.white24,
                              color:
                                  Colors
                                      .purpleAccent, // Changed to purple accent
                              borderRadius: BorderRadius.circular(4),
                              minHeight: 6,
                            ),
                          ],
                        ),
                      );
                    });
                  })(),
                ],
              ),
            ),

            // Added Motivational Carousel Here
            const SizedBox(height: 24),
            const _MotivationalCarousel(),
          ],
        );
      },
    );
  }
}

class _MotivationalCarousel extends StatefulWidget {
  const _MotivationalCarousel();

  @override
  State<_MotivationalCarousel> createState() => _MotivationalCarouselState();
}

class _MotivationalCarouselState extends State<_MotivationalCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> _quotes = [
    "طيف وصالح خالفو قانون 6 لسنة 2000 وبكيفهم..\nطيف وصالح خالفو المادة 42 من قانون التعليم وبكيفهم..\nطيف وصالح صوتو على قرار لمجلس الوزراء وما طبقو وبكيفهم..",
    "وتم تعيين أبناء مسؤولين ونشرنا عنهم وغلسو ومشوهم وبكيفهم..\nتريد هسة يخصص لغيرك ويعوفك وهم بكيفة؟؟",
    "الخطوة الجاية بعنوان أما يطلع كتاب تخصيص دفعة 23 #وبكيفنا أو تواجهون ناس هواي صبرو وتحملو وصبرهم نفذ🔥🤌.",
    "احنا المجموعة الطبية\nناخذ حقنا من الماليـة\n#ثورة_ياعلي",
    "ورقة الـ A4 التي قد تبدو صغيرة بأبعادها: العرض 21 سم والارتفاع 29.7 سم، ليست مجرد ورقة عادية، بل هي الورقة التي تختزن داخلها أمنيات ومستقبل أكثر من 21 ألف خريج ينتظرون حقهم بالتعيين.\n\nأمَا آن الأوان لاستخراج هذه الورقة التي ستغير مصير آلاف العوائل وتُنهي معاناة امتدت لسنوات؟\n\nاستعدوا يا أبطال لقد حان وقت استخراج الحلم.",
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        final nextPage = (_currentPage + 1) % _quotes.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
        setState(() {
          _currentPage = nextPage;
        });
        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        children: [
          const Icon(Icons.campaign_rounded, color: Colors.white, size: 40),
          const SizedBox(height: 16),
          SizedBox(
            height: 200, // Fixed height for quotes
            child: PageView.builder(
              controller: _pageController,
              itemCount: _quotes.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index % _quotes.length);
              },
              itemBuilder: (context, index) {
                // To allow infinite looping illusion (simple mock)
                // Use modulo if strict infinite loop needed, but here list is short.
                return Center(
                  child: SingleChildScrollView(
                    child: Text(
                      _quotes[index % _quotes.length],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.6,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_quotes.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index ? Colors.white : Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _GlassCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 16,
                spreadRadius: 4,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class AttendanceForm extends StatefulWidget {
  const AttendanceForm({super.key});

  @override
  State<AttendanceForm> createState() => _AttendanceFormState();
}

class _AttendanceFormState extends State<AttendanceForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _guestCountController = TextEditingController(
    text: '0',
  ); // New Controller
  String? _selectedGovernorate;
  bool _isLoading = false;

  final List<String> _governorates = [
    'بغداد',
    'البصرة',
    'نينوى',
    'أربيل',
    'السليمانية',
    'دهوك',
    'النجف الأشرف',
    'كربلاء المقدسة',
    'واسط',
    'بابل',
    'ديالى',
    'صلاح الدين',
    'الأنبار',
    'ميسان',
    'ذي قار',
    'المثنى',
    'القادسية',
    'كركوك',
  ];

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final int guests = int.tryParse(_guestCountController.text) ?? 0;

      try {
        await FirebaseFirestore.instance.collection('attendees').add({
          'name': _nameController.text,
          'department': _departmentController.text,
          'governorate': _selectedGovernorate,
          'guest_count': guests, // Save guests
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          _showSuccessDialog();
        }
      } catch (e) {
        print("Submission Error: $e");
        if (mounted) {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('خطأ في الاتصال'),
                  content: Text(
                    'حدث خطأ أثناء الحفظ:\n$e\n\nتأكد من إعدادات Firestore Rules وأن المفاتيح صحيحة.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('حسناً'),
                    ),
                  ],
                ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFFF3E5F5), // Light Purple
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            icon: const Icon(
              Icons.check_circle,
              color: Color(0xFF8E24AA),
              size: 48,
            ), // Purple icon
            title: const Text(
              'تم التسجيل بنجاح',
              style: TextStyle(color: Color(0xFF4A148C)),
            ),
            content: Text(
              'شكراً لك ${_nameController.text}!\nتم تسجيل حضورك بنجاح.\nنراك في المظاهرات!',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _nameController.clear();
                  _departmentController.clear();
                  _guestCountController.text = '0'; // Reset guest count
                  setState(() {
                    _selectedGovernorate = null;
                  });
                },
                child: const Text(
                  'حسناً',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8E24AA),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _departmentController.dispose();
    _guestCountController.dispose(); // Dispose new controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo Image
          Container(
            height: 120, // Reasonable height for logo
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
          ),
          const SizedBox(height: 16),
          const Text(
            'سجل حضورك',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'صوتك يحدث فارقاً',
            style: TextStyle(fontSize: 16, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          _buildGlassyTextField(
            controller: _nameController,
            label: 'الاسم الثلاثي',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          _buildGlassyTextField(
            controller: _departmentController,
            label: 'القسم / الكلية',
            icon: Icons.school_outlined,
          ),
          const SizedBox(height: 16),
          _buildGlassyDropdown(),

          const SizedBox(height: 16),
          // Guest Count Field
          _buildGlassyTextField(
            controller: _guestCountController,
            label: 'كم شخص سيحضر معك؟ (عداك)',
            icon: Icons.group_add_outlined,
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 32),
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitForm,
              icon:
                  _isLoading
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(
                        Icons.send_rounded,
                        color: Color(0xFF8E24AA),
                      ), // Purple icon
              label: Text(
                _isLoading ? 'جاري التسجيل...' : 'تسجيل الحضور',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8E24AA),
                ), // Purple text
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF8E24AA),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassyTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.purpleAccent), // Purple accent
        filled: true,
        fillColor: Colors.black12,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.purpleAccent,
          ), // Purple accent
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
      validator: (value) => value!.isEmpty ? 'هذا الحقل مطلوب' : null,
    );
  }

  Widget _buildGlassyDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGovernorate,
      style: const TextStyle(
        color: Colors.black87,
      ), // Dropdown items text color
      decoration: InputDecoration(
        labelText: 'المحافظة',
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(
          Icons.location_on_outlined,
          color: Colors.purpleAccent,
        ), // Purple accent
        filled: true,
        fillColor: Colors.black12,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.purpleAccent,
          ), // Purple accent
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
      dropdownColor: const Color(0xFFF3E5F5), // Light Purple
      items:
          _governorates.map((String gov) {
            return DropdownMenuItem<String>(value: gov, child: Text(gov));
          }).toList(),
      onChanged: (val) => setState(() => _selectedGovernorate = val),
      validator: (value) => value == null ? 'يرجى اختيار المحافظة' : null,
    );
  }
}
