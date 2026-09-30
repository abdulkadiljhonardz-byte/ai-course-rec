class SeedCourse {
  const SeedCourse({
    required this.code,
    required this.name,
    required this.category,
    required this.description,
    this.isPaid = false,
  });

  final String code;
  final String name;
  final String category;
  final String description;
  final bool isPaid;
}

class SeedRule {
  const SeedRule({
    required this.courseCode,
    required this.minMath,
    required this.minScience,
    required this.minEnglish,
    required this.weightMath,
    required this.weightScience,
    required this.weightEnglish,
    required this.preferredInterest,
  });

  final String courseCode;
  final int minMath;
  final int minScience;
  final int minEnglish;
  final double weightMath;
  final double weightScience;
  final double weightEnglish;
  final String preferredInterest;
}

class SeedData {
  const SeedData._();

  static const List<SeedCourse> courses = [
    SeedCourse(
      code: 'BSAGRI',
      name: 'BS in Agriculture',
      category: 'Agriculture',
      description:
          'This program focuses on crop production, soil management, farm operations, agricultural technology, and sustainable food systems. Students study plant science, pest control, farm planning, and resource management to prepare for careers in farming, agribusiness, extension work, and agricultural development.',
    ),
    SeedCourse(
      code: 'BSABM',
      name: 'BS in Agri-Business Management',
      category: 'Business',
      description:
          'This course combines business management with agriculture-based enterprises. Students learn entrepreneurship, financial planning, marketing, supply chain management, and operations for farms, food production, and agri-related businesses. It is suited for students who want to manage or build agricultural enterprises.',
      isPaid: true,
    ),
    SeedCourse(
      code: 'BSNUR',
      name: 'BS in Nursing',
      category: 'Health',
      description:
          'This program prepares students for patient care in hospitals, clinics, and community settings. It covers anatomy, physiology, pharmacology, health assessment, maternal and child care, and clinical practice. It is ideal for students who want to work in healthcare and serve patients directly.',
      isPaid: true,
    ),
    SeedCourse(
      code: 'BSBIO',
      name: 'BS in Biology',
      category: 'Health',
      description:
          'This course develops strong knowledge in living organisms, laboratory investigation, research methods, genetics, ecology, and microbiology. It is a good foundation for students interested in research, medicine, environmental work, laboratory science, or advanced health-related studies.',
    ),
    SeedCourse(
      code: 'BSMATH',
      name: 'BS in Mathematics',
      category: 'Technology',
      description:
          'This program centers on advanced mathematics, logical reasoning, data analysis, and problem solving. Students study algebra, calculus, statistics, mathematical modeling, and theoretical concepts that support careers in analytics, teaching, research, finance, and technology-driven fields.',
      isPaid: true,
    ),
    SeedCourse(
      code: 'BAELS',
      name: 'BA in English Language Studies',
      category: 'Language',
      description:
          'This course focuses on communication, grammar, writing, linguistics, literature-related language study, and language teaching. It helps students develop strong speaking, writing, and analytical skills for careers in education, media, writing, communication, and language services.',
    ),
    SeedCourse(
      code: 'BAIS',
      name: 'BA in Islamic Studies',
      category: 'Social Science',
      description:
          'This program explores Islamic beliefs, history, law, ethics, culture, and their role in society. Students examine religious texts, community issues, and moral leadership. It is suitable for those interested in teaching, community service, religious leadership, and social understanding.',
    ),
    SeedCourse(
      code: 'BAPOLS',
      name: 'BA in Political Science',
      category: 'Social Science',
      description:
          'This course studies government systems, public policy, political theory, law, and current social issues. Students build skills in analysis, debate, research, and public communication. It prepares learners for careers in government, public service, law, policy work, and advocacy.',
    ),
    SeedCourse(
      code: 'BSBA',
      name: 'BS in Business Administration',
      category: 'Business',
      description:
          'This program covers core business areas such as management, marketing, human resources, operations, and strategic planning. Students learn how organizations run, how to lead teams, and how to make sound business decisions. It is a practical choice for future managers and entrepreneurs.',
      isPaid: true,
    ),
    SeedCourse(
      code: 'BSA',
      name: 'BS in Accountancy',
      category: 'Business',
      description:
          'This course focuses on accounting systems, financial reporting, auditing, taxation, and business law. Students develop accuracy, discipline, and analytical skills needed to examine financial records and support decision-making. It is suited for those aiming for accounting, auditing, or finance careers.',
      isPaid: true,
    ),
    SeedCourse(
      code: 'BSIT',
      name: 'BS in Information Technology',
      category: 'Technology',
      description:
          'This program teaches students how to build and manage technology solutions for real-world use. Topics include programming, web and mobile development, databases, networking, systems administration, and technical support. It is ideal for students who want practical careers in the IT industry.',
      isPaid: true,
    ),
    SeedCourse(
      code: 'BSCS',
      name: 'BS in Computer Science',
      category: 'Technology',
      description:
          'This course focuses on software development, algorithms, data structures, computer architecture, and problem solving through computation. It suits students who enjoy logic, coding, and designing systems, and it prepares them for careers in software engineering, research, and advanced computing fields.',
      isPaid: true,
    ),
    SeedCourse(
      code: 'BSED',
      name: 'Bachelor of Secondary Education',
      category: 'Education',
      description:
          'This program prepares students to teach high school learners through subject specialization, lesson planning, classroom management, assessment, and teaching strategies. It is designed for future educators who want to guide adolescents in academic and personal development.',
    ),
    SeedCourse(
      code: 'BEED',
      name: 'Bachelor of Elementary Education',
      category: 'Education',
      description:
          'This course trains students to teach children in the elementary level using child-centered methods, inclusive instruction, classroom management, and foundational literacy and numeracy development. It is best for those who want to build young learners confidence and basic academic skills.',
    ),
  ];

  static const List<SeedRule> rules = [
    SeedRule(
      courseCode: 'BSAGRI',
      minMath: 70,
      minScience: 75,
      minEnglish: 70,
      weightMath: 0.30,
      weightScience: 0.45,
      weightEnglish: 0.25,
      preferredInterest: 'Agriculture',
    ),
    SeedRule(
      courseCode: 'BSABM',
      minMath: 70,
      minScience: 70,
      minEnglish: 75,
      weightMath: 0.30,
      weightScience: 0.20,
      weightEnglish: 0.50,
      preferredInterest: 'Business',
    ),
    SeedRule(
      courseCode: 'BSNUR',
      minMath: 75,
      minScience: 85,
      minEnglish: 80,
      weightMath: 0.25,
      weightScience: 0.50,
      weightEnglish: 0.25,
      preferredInterest: 'Health',
    ),
    SeedRule(
      courseCode: 'BSBIO',
      minMath: 75,
      minScience: 82,
      minEnglish: 75,
      weightMath: 0.25,
      weightScience: 0.50,
      weightEnglish: 0.25,
      preferredInterest: 'Health',
    ),
    SeedRule(
      courseCode: 'BSMATH',
      minMath: 85,
      minScience: 75,
      minEnglish: 70,
      weightMath: 0.55,
      weightScience: 0.25,
      weightEnglish: 0.20,
      preferredInterest: 'Technology',
    ),
    SeedRule(
      courseCode: 'BAELS',
      minMath: 65,
      minScience: 65,
      minEnglish: 85,
      weightMath: 0.10,
      weightScience: 0.15,
      weightEnglish: 0.75,
      preferredInterest: 'Language',
    ),
    SeedRule(
      courseCode: 'BAIS',
      minMath: 65,
      minScience: 65,
      minEnglish: 80,
      weightMath: 0.10,
      weightScience: 0.20,
      weightEnglish: 0.70,
      preferredInterest: 'Islamic',
    ),
    SeedRule(
      courseCode: 'BAPOLS',
      minMath: 68,
      minScience: 70,
      minEnglish: 82,
      weightMath: 0.15,
      weightScience: 0.25,
      weightEnglish: 0.60,
      preferredInterest: 'Social Science',
    ),
    SeedRule(
      courseCode: 'BSBA',
      minMath: 70,
      minScience: 68,
      minEnglish: 78,
      weightMath: 0.25,
      weightScience: 0.20,
      weightEnglish: 0.55,
      preferredInterest: 'Business',
    ),
    SeedRule(
      courseCode: 'BSA',
      minMath: 80,
      minScience: 72,
      minEnglish: 80,
      weightMath: 0.45,
      weightScience: 0.15,
      weightEnglish: 0.40,
      preferredInterest: 'Business',
    ),
    SeedRule(
      courseCode: 'BSIT',
      minMath: 80,
      minScience: 75,
      minEnglish: 70,
      weightMath: 0.45,
      weightScience: 0.35,
      weightEnglish: 0.20,
      preferredInterest: 'Technology',
    ),
    SeedRule(
      courseCode: 'BSCS',
      minMath: 85,
      minScience: 80,
      minEnglish: 70,
      weightMath: 0.50,
      weightScience: 0.35,
      weightEnglish: 0.15,
      preferredInterest: 'Technology',
    ),
    SeedRule(
      courseCode: 'BSED',
      minMath: 72,
      minScience: 72,
      minEnglish: 78,
      weightMath: 0.30,
      weightScience: 0.30,
      weightEnglish: 0.40,
      preferredInterest: 'Education',
    ),
    SeedRule(
      courseCode: 'BEED',
      minMath: 70,
      minScience: 70,
      minEnglish: 80,
      weightMath: 0.25,
      weightScience: 0.25,
      weightEnglish: 0.50,
      preferredInterest: 'Education',
    ),
  ];
}
