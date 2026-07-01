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
    // CV / Resume
    TemplateItem(
      title: 'Professional CV',
      description: 'A classic, clean resume format for corporate & technical roles.',
      category: 'CV',
      icon: Icons.badge_rounded,
      content: '''# [Your Name]
**[Your Profession / Title]**

- 📧 Email: info@domain.com
- 📞 Phone: +123 4567 890
- 🌐 Portfolio: portfolio.com
- 📍 Address: New York, USA

---

## Executive Summary
Highly motivated professional with 5+ years of experience in software development and team leadership. Proven track record of delivering high-quality web and mobile applications.

## Professional Experience

### Senior Developer | Tech Corp (2022 - Present)
- Led a team of 5 developers to deliver cloud-based enterprise solutions.
- Improved application performance by 40% using optimization techniques.
- Mentored junior engineers and established testing guidelines.

### Software Engineer | Dev Studio (2019 - 2022)
- Developed and maintained native mobile applications in Flutter.
- Collaborated with product designers to implement pixel-perfect interfaces.

## Education
- **B.Sc. in Computer Science** | University of Technology (2015 - 2019)

## Skills
- Flutter, Dart, Java, Python
- SQLite, PostgreSQL, Firebase
- Git, CI/CD, Agile Methodologies
''',
    ),
    TemplateItem(
      title: 'Creative CV',
      description: 'A vibrant, modern resume layout for designers, developers, and creatives.',
      category: 'CV',
      icon: Icons.brush_rounded,
      content: '''# 🌟 [YOUR NAME]
🚀 *Creative UI/UX Designer & Frontend Developer*

---

### 📬 Contact Info
- 📧 Email: hello@creative.design
- 🌐 Web: www.creativedesign.me
- 📍 Location: London, UK

---

### 🛠️ Core Skills
- **Design**: Figma, Adobe XD, Prototyping, Wireframing
- **Frontend**: HTML5, CSS3, JavaScript, Flutter, React
- **Concepts**: User Research, Design Systems, Typography

---

### 💼 Experience

**Lead Designer** | Design Lab | *2021 - Present*
- Created custom branding and digital identities for over 15 startups.
- Redesigned the main dashboard portal, increasing user retention by 25%.

**UI Designer** | Web Agency | *2019 - 2021*
- Designed and built responsive web layouts for global e-commerce clients.
- Collaborated closely with backend engineers to integrate API responses.

---

### 🎓 Education
**B.FA in Graphic Design** | Arts Academy | *2015 - 2018*
''',
    ),
    TemplateItem(
      title: 'Modern CV',
      description: 'A structured, clean-cut modern resume layout with clear tables and listings.',
      category: 'CV',
      icon: Icons.dashboard_customize_rounded,
      content: '''# Name: [Your Name]
**Title: Full Stack Software Engineer**

---

### PROFILE
Solution-oriented engineer with deep expertise in full-stack web and mobile systems. Proven record of building secure, scalable architectures.

### PROFESSIONAL EXPERIENCE

**Full Stack Developer** - Solutions Inc. (2020 - Present)
- Designed and implemented microservices architectures handling 100k+ daily requests.
- Built cross-platform applications using Flutter and Riverpod.

**Backend Engineer** - Core Systems (2018 - 2020)
- Developed secure API endpoints and managed relational database schemas.

### EDUCATION
- **Master of Computer Applications** | Global University (2016 - 2018)
- **Bachelor of Computer Applications** | Global University (2013 - 2016)
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
