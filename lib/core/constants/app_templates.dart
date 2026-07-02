import 'package:flutter/material.dart';

class TemplateItem {
  final String title;
  final String description;
  final String category;
  final String content;
  final IconData icon;

  const TemplateItem({
    required this.title,
    required this.description,
    required this.category,
    required this.content,
    required this.icon,
  });
}

class AppTemplates {
  static const List<TemplateItem> list = [
    TemplateItem(
      title: 'Blank Document',
      description: 'Start with a completely empty document.',
      category: 'Blank',
      icon: Icons.note_add_rounded,
      content: '# New Document\n\nWrite content here...',
    ),
    
    // --- SINGLE COLUMN CVs (Top - Most Compatible) ---
    
    TemplateItem(
      title: 'Professional Modern CV',
      description: 'A sleek, single-column design with a clear hierarchy and modern look.',
      category: 'CV',
      icon: Icons.badge_rounded,
      content: '''# [YOUR FULL NAME]
### [Desired Job Title | Senior Specialist]

---

**[Email Address]**  |  **[Phone Number]**  |  **[LinkedIn/Portfolio]**  |  **[Location]**

---

## 🚀 PROFESSIONAL PROFILE
Highly motivated and results-oriented professional with 5+ years of experience in [Your Industry]. Proven ability to lead teams, optimize workflows, and deliver high-impact results. Expert in [Skill 1], [Skill 2], and [Skill 3].

## 💼 WORK EXPERIENCE

#### **Lead Developer** | Tech Innovations Inc. | *Jan 2021 — Present*
- Spearheaded the development of a flagship mobile application with 1M+ downloads.
- Improved system performance by 40% through code optimization and architecture refactoring.
- Led a cross-functional team of 8 to deliver projects ahead of schedule.

#### **Senior Engineer** | Global Solutions Ltd. | *June 2018 — Dec 2020*
- Built and maintained secure, scalable cloud infrastructure for fintech clients.
- Implemented automated CI/CD pipelines, reducing deployment errors by 25%.
- Mentored junior staff and established internal best practices for code quality.

## 🎓 EDUCATION
- **Master of Science in Technology** | National University (2018)
- **Bachelor of Engineering** | City Technical Institute (2015)

## 🛠️ CORE EXPERTISE
- **Programming**: Dart, Flutter, Python, SQL, JavaScript
- **Infrastructure**: AWS, Docker, Firebase, Kubernetes
- **Soft Skills**: Strategic Planning, Leadership, Project Management
''',
    ),

    TemplateItem(
      title: 'Minimalist Clean CV',
      description: 'A beautiful, minimal design that focuses entirely on your content.',
      category: 'CV',
      icon: Icons.auto_awesome_mosaic_rounded,
      content: '''# [YOUR NAME]
**[Job Title / Tagline]**

---

📧 [email@example.com]
📞 [+880 1234-567890]
🌐 [portfolio.me]
📍 [Dhaka, Bangladesh]

---

### SUMMARY
Dedicated professional with a passion for excellence and a track record of success in [Your Field]. Expert at solving complex problems and building scalable solutions.

### EXPERIENCE

**Senior Mobile Developer** | Tech Solutions | *2021 - Now*
- Developed 5+ high-performance Flutter applications.
- Integrated third-party APIs and complex payment gateways.
- Optimized app memory usage, reducing crashes by 15%.

**Junior Developer** | App Studio | *2019 - 2021*
- Assisted in building cross-platform apps for global clients.
- Conducted unit testing and fixed critical bugs in legacy systems.

### EDUCATION
- **B.Sc. in Computer Science** | University of Engineering (2018)

### SKILLS
- **Mobile**: Flutter, Dart, Android, iOS
- **Backend**: Node.js, Firebase, MongoDB
- **Tools**: Git, Figma, JIRA, Trello
''',
    ),

    TemplateItem(
      title: 'Creative Brand CV',
      description: 'A stylish layout for creative professionals to showcase their brand.',
      category: 'CV',
      icon: Icons.brush_rounded,
      content: '''# 🎨 [YOUR BRAND NAME]
### *Visual Storyteller & UI Designer*

---

### 📬 CONNECT
- 📧 hello@creative.design
- 🌐 www.creativedesign.me
- 📍 London, UK

### 🌟 HIGHLIGHTS
- **5+ Years** of experience in digital product design and branding.
- **Expertise** in high-fidelity prototyping and user-centered research.
- **Award-winning** portfolio featured on top design platforms.

---

### 💼 MY JOURNEY

**Senior UI Designer** | Pixel Lab | *2021 - Present*
- Created custom branding and digital identities for over 15 startups.
- Redesigned the main dashboard portal, increasing user engagement by 30%.

**Graphic Designer** | Web Agency | *2018 - 2021*
- Designed responsive web layouts for global e-commerce brands.
- Collaborated with developers to ensure pixel-perfect implementation.

### 🎓 ACADEMIC RECORD
**B.FA in Graphic Design** | Arts Academy | *2015 - 2018*

### 🛠️ DESIGN TOOLS
- **Design**: Figma, Adobe XD, Photoshop, Illustrator
- **Motion**: After Effects, Lottie, Rive
- **Process**: Wireframing, User Flow, Design Systems
''',
    ),

    // --- 2-COLUMN CVs (Bottom - For Information Dense Resumes) ---
    
    TemplateItem(
      title: 'Premium Sidebar CV (2-Col)',
      description: 'A professional 2-column layout with a sidebar for info and skills.',
      category: 'CV',
      icon: Icons.view_sidebar_rounded,
      content: '''# [Your Name]
**[Senior Position Title]**

---

| **CONTACT & SKILLS** | **CAREER SUMMARY** |
| :--- | :--- |
| **GET IN TOUCH** | **PROFESSIONAL PROFILE** |
| ✉️ your@email.com | Results-driven engineer with 5+ years |
| 📞 +880123456789 | of experience in building enterprise- |
| 📍 Dhaka, BD | grade mobile and cloud systems. |
| 🌐 portfolio.link | |
| | **EXPERIENCE** |
| **TOP SKILLS** | **Lead Mobile Dev** \| Tech Corp |
| • Flutter & Dart | *2021 - Present* |
| • Firebase / SQL | • Scaling apps to 1M+ active users. |
| • Node.js / Go | • Implementing Clean Architecture. |
| • AWS / DevOps | |
| • Team Mgmt | **Software Engineer** \| Startup |
| | *2018 - 2020* |
| **LANGUAGES** | • Built core features for fintech app. |
| • English (Expert) | • Reduced API latency by 50%. |
| • Bengali (Native) | |
| | **EDUCATION** |
| **AWARDS** | • **B.Sc. in CS** \| Tech University |
| • Best Dev 2023 | • **HSC** \| Science Background |

---
''',
    ),

    TemplateItem(
      title: 'Executive Split CV (2-Col)',
      description: 'A high-level layout separating expertise from experience.',
      category: 'CV',
      icon: Icons.dashboard_customize_rounded,
      content: '''# [YOUR FULL NAME]
**[Executive Management Title]**

---

| **EXPERTISE** | **CAREER TRACK** |
| :--- | :--- |
| **CORE SKILLS** | **PROFESSIONAL ROLE** |
| • Strategic Ops | **Project Director** \| Lead Corp |
| • Team Leadership | *2021 - Present* |
| • Budget Mgmt | • Managing budgets over \$5M. |
| • Risk Analysis | • Directing 50+ staff members. |
| • Digital Trans. | • Improved ROI by 20% in 1 year. |
| | |
| **TECH STACK** | **Operations Manager** \| Global |
| • System Design | *2018 - 2021* |
| • Data Science | • Designed core infra workflows. |
| • Cyber Security | • Implemented ISO standards. |
| • Cloud Arch. | • Led digital migration projects. |
| | |
| **CERTIFICATIONS** | **ACADEMIC BACKGROUND** |
| • PMP Certified | • **MBA** \| Business School |
| • Azure Expert | • **B.Eng** \| Engineering College |
| • Scrum Master | • **Diploma** \| Project Mgmt |

---
''',
    ),

    // Cover Letters
    TemplateItem(
      title: 'Standard Cover Letter',
      description: 'A polite, formal cover letter suitable for any application.',
      category: 'Cover Letter',
      icon: Icons.mark_as_unread_rounded,
      content: '''[Your Name]
[Your Address]
[Date]

[Hiring Manager's Name]
[Company Name]
[Company Address]

Dear [Hiring Manager's Name],

I am writing to express my strong interest in the [Job Title] position at [Company Name]. With my background in [Your Field/Key Skill], I am confident I would be a valuable asset to your team.

I have spent the last [Number] years developing expertise in [Key Expertise]. In my previous role at [Previous Company Name], I successfully [Mention a Key Achievement]. I believe these skills align perfectly with the goals of [Company Name].

Thank you for your time and consideration. I look forward to the possibility of discussing this opportunity further.

Sincerely,

[Your Name]
''',
    ),
    TemplateItem(
      title: 'Executive Cover Letter',
      description: 'An impact-focused letter for leadership and executive roles.',
      category: 'Cover Letter',
      icon: Icons.business_center_rounded,
      content: '''Dear [Recipient Title & Name],

**Re: Application for [Executive Position Title]**

I am writing to formally apply for the [Executive Position Title] at [Company Name]. Throughout my career, I have specialized in driving strategic growth, scaling operations, and leading high-performing teams to achieve excellence.

At my current organization, [Current Company], I directed [Project/Initiative] which resulted in a [Percentage]% increase in efficiency and generated \$[Amount] in new revenue. My approach combines data-driven strategy with collaborative leadership.

I am eager to bring this level of dedication and strategic planning to [Company Name]. Let us schedule a time to discuss how my vision aligns with your company's objectives.

Sincerely,

[Your Name]
''',
    ),
    TemplateItem(
      title: 'Creative Cover Letter',
      description: 'A catchy, casual cover letter highlighting personality and drive.',
      category: 'Cover Letter',
      icon: Icons.rocket_launch_rounded,
      content: '''Hi [Team/Hiring Manager Name],

I've been following [Company Name] and fell in love with your project [Project Name]. When I saw the opening for [Job Title], I knew I had to apply!

Here is why I think we would be a great match:
- **[Point 1]**: I have spent 3 years building tools like yours and love solving complex challenges.
- **[Point 2]**: I'm obsessed with clean, maintainable code and building awesome user experiences.

I'd love to chat about how I can contribute to the team!

Best regards,

[Your Name]
''',
    ),
    // Leave Applications
    TemplateItem(
      title: 'Casual Leave Application',
      description: 'Request casual leave for personal reasons.',
      category: 'Leave Application',
      icon: Icons.home_repair_service_rounded,
      content: '''Subject: Application for Casual Leave

To,
The Manager / Principal,
[Company/School Name]

Dear Sir/Madam,

I am writing to formally request casual leave for [Number] days, starting from [Start Date] to [End Date], due to personal commitments that require my immediate attention.

I have coordinated with [Colleague's Name] to cover my duties during my absence, and I will be reachable via email in case of emergencies.

Thank you for your understanding and support.

Sincerely,

[Your Name]
[Your Designation]
''',
    ),
    TemplateItem(
      title: 'Medical Leave Application',
      description: 'Request leave for medical recovery or doctor advice.',
      category: 'Leave Application',
      icon: Icons.medical_services_rounded,
      content: '''Subject: Application for Medical Leave

To,
[Manager's Name],
[Company Name]

Dear [Manager's Name],

Please accept this request for medical leave from [Start Date] to [End Date]. I have been advised by my doctor to take complete rest to recover from [Illness/Medical Condition].

I have attached the doctor's medical certificate for your reference. I will ensure all pending reports are handed over today.

Sincerely,

[Your Name]
[Your Designation]
''',
    ),
    TemplateItem(
      title: 'Personal Leave Application',
      description: 'A short personal leave request.',
      category: 'Leave Application',
      icon: Icons.person_remove_rounded,
      content: '''Subject: Application for Personal Leave of Absence

Dear [Manager's Name],

I am writing to request a short leave of absence for personal reasons from [Start Date] to [End Date]. 

I will ensure all my current projects are updated and documented so that the team experiences no disruption. I will be back in the office on [Return Date].

Thank you for your consideration.

Best regards,

[Your Name]
''',
    ),
    // Invoice
    TemplateItem(
      title: 'Freelance Invoice',
      description: 'An itemized layout for independent contractors and freelancers.',
      category: 'Invoice',
      icon: Icons.receipt_long_rounded,
      content: '''# INVOICE
**Invoice No:** #INV-2026-001 | **Date:** [Current Date]

### Bill To:
[Client Name]
[Client Company]
[Address]

### Description of Services
| Item Description | Hours | Rate | Total |
|---|---|---|---|
| Frontend Development (Flutter) | 40 | \$50 | \$2,000 |
| Consulting & Architecture Planning | 5 | \$75 | \$375 |
| UI/UX Revisions | 4 | \$50 | \$200 |

**Total Due: \$2,575**

*Payment Terms: Due within 15 days of invoice date.*
''',
    ),
    TemplateItem(
      title: 'Detailed Product Invoice',
      description: 'An invoice format for listing physical or digital products.',
      category: 'Invoice',
      icon: Icons.shopping_bag_rounded,
      content: '''# PRODUCT INVOICE
**Invoice Date:** [Current Date] | **Invoice No:** #INV-PD-09

### Supplier:
[Your Business Name]
[Your Address]

### Buyer:
[Client/Buyer Name]
[Client Address]

### Itemized Details:
- **Product A**: 10 units @ \$15.00 = \$150.00
- **Product B**: 5 units @ \$30.00 = \$150.00
- **Shipping Fee**: \$20.00
- **Taxes (5%)**: \$15.00

**Grand Total: \$335.00**

*Thank you for your business!*
''',
    ),
    // Agreements
    TemplateItem(
      title: 'Non-Disclosure Agreement (NDA)',
      description: 'A standard NDA contract framework for project confidentiality.',
      category: 'Agreement',
      icon: Icons.gavel_rounded,
      content: '''# MUTUAL NON-DISCLOSURE AGREEMENT (NDA)

This Agreement is entered into on [Date] between:
- **Disclosing Party**: [Name/Company]
- **Receiving Party**: [Name/Company]

### 1. Confidential Information
"Confidential Information" refers to any proprietary information, technical data, trade secrets, or know-how disclosed by either party.

### 2. Obligations of Confidentiality
The Receiving Party agrees:
- To keep the Disclosing Party's Confidential Information strictly confidential.
- Not to disclose such information to any third party without prior consent.

### 3. Term
This Agreement and the obligations shall remain in effect for [Number] years from the date of disclosure.
''',
    ),
    TemplateItem(
      title: 'Lease Agreement',
      description: 'A basic rental lease agreement draft between landlord and tenant.',
      category: 'Agreement',
      icon: Icons.house_rounded,
      content: '''# LEASE AGREEMENT

This Lease Agreement is made on [Date] between:
- **Landlord**: [Name of Landlord]
- **Tenant**: [Name of Tenant]

### 1. Property Description
The Landlord agrees to rent out the residential property located at:
*Address: [Address of Property]*

### 2. Lease Term & Rent Payment
- **Lease Term**: 12 Months, beginning on [Start Date].
- **Monthly Rent**: \$[Amount] USD, due on the 1st of each month.
- **Security Deposit**: \$[Amount] USD

### 3. Maintenance & Regulations
The Tenant agrees to keep the premises in good condition and comply with local housing rules.
''',
    ),
    TemplateItem(
      title: 'Project Services Agreement',
      description: 'A contractual agreement defining provider services and client payment.',
      category: 'Agreement',
      icon: Icons.handshake_rounded,
      content: '''# PROJECT SERVICES AGREEMENT

**Date:** [Current Date]

**Parties:**
1. **Provider**: [Your Company/Name]
2. **Client**: [Client Company/Name]

### 1. Scope of Work
Provider agrees to deliver the following services:
- [Service/Feature 1]
- [Service/Feature 2]
- [Service/Feature 3]

### 2. Payment Terms
Client shall pay Provider the total sum of \$[Amount] USD upon completion of the agreed deliverables, within 10 days of receiving the invoice.

### 3. Intellectual Property
Upon full payment, all custom deliverables and intellectual property will be transferred to the Client.
''',
    ),
  ];
}
