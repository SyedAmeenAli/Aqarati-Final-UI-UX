/// Professional engagements (client side) and reviews copy. ARABIC IS DRAFT COPY and needs native review.
/// Rules (architecture v2.6): the other side confirms within 14 days; a review is allowed within 60 days
/// of confirmation; 1 to 5 stars, 10 to 500 characters; every review is moderated before it is public.
const Map<String, (String, String)> engagementStrings = {
  'ce.row': ('Your engagements', 'ارتباطاتك المهنية'),
  'ce.engage.cta': ('Request an engagement', 'اطلب ارتباطاً مهنياً'),
  'ce.req.title': ('Request an engagement', 'اطلب ارتباطاً مهنياً'),
  'ce.req.sub': ('With {name}', 'مع {name}'),
  'ce.req.what.t': ('What this is', 'ما هذا'),
  'ce.req.what.b': (
    'You tell AQARATI you worked with this professional. They confirm it. Once both sides have confirmed, you can write a review. This is not a booking, a viewing or a maintenance request.',
    'تخبر عقاراتي أنك عملت مع هذا المهني. يؤكد هو ذلك. وعندما يؤكد الطرفان يمكنك كتابة تقييم. هذا ليس حجزاً ولا معاينة ولا طلب صيانة.',
  ),
  'ce.req.rules.t': ('The rules', 'القواعد'),
  'ce.req.rules.1': (
    'The professional has 14 days to confirm.',
    'لدى المهني 14 يوماً للتأكيد.',
  ),
  'ce.req.rules.2': (
    'After both confirm, you have 60 days to write a review.',
    'بعد تأكيد الطرفين لديك 60 يوماً لكتابة تقييم.',
  ),
  'ce.req.send': ('Send request', 'إرسال الطلب'),
  'ce.req.signin': (
    'Log in to request an engagement.',
    'سجّل الدخول لطلب ارتباط مهني.',
  ),
  'ce.req.login': ('Log in', 'تسجيل الدخول'),
  'ce.req.demo': (
    'Demo: nothing is sent to the professional.',
    'تجريبي: لا يُرسل شيء إلى المهني.',
  ),
  'ce.list.title': ('Your engagements', 'ارتباطاتك المهنية'),
  'ce.list.sub': (
    'Requests you made with professionals.',
    'الطلبات التي قدمتها للمهنيين.',
  ),
  'ce.list.empty.t': ('No engagements yet', 'لا توجد ارتباطات بعد'),
  'ce.list.empty.b': (
    'Open a professional\'s profile to request one after you have worked together.',
    'افتح ملف مهني لتطلب ارتباطاً بعد أن تعملا معاً.',
  ),
  'ce.list.cta': ('Find professionals', 'ابحث عن مهنيين'),
  'ce.list.error': (
    'We could not load your engagements.',
    'تعذّر تحميل ارتباطاتك.',
  ),
  'ce.d.title': ('Engagement', 'الارتباط المهني'),
  'ce.d.requested': ('Requested', 'تاريخ الطلب'),
  'ce.d.confirmBy': ('They can confirm until', 'يمكنه التأكيد حتى'),
  'ce.d.reviewBy': ('You can review until', 'يمكنك التقييم حتى'),
  'ce.d.cancel': ('Cancel request', 'إلغاء الطلب'),
  'ce.d.confirm': ('Confirm we worked together', 'أؤكد أننا عملنا معاً'),
  'ce.d.review': ('Write a review', 'اكتب تقييماً'),
  'ce.d.notFound': (
    'We could not find this engagement.',
    'لم نجد هذا الارتباط.',
  ),
  'ce.d.err': (
    'We could not do that. The engagement is unchanged.',
    'تعذّر ذلك. الارتباط لم يتغير.',
  ),
  'ce.d.done.confirm': (
    'Confirmed. You can now write a review.',
    'تم التأكيد. يمكنك الآن كتابة تقييم.',
  ),
  'ce.d.done.cancel': ('Request cancelled.', 'تم إلغاء الطلب.'),
  'ce.ph.awaitingProfessional': ('Waiting for them', 'بانتظار المهني'),
  'ce.ph.awaitingMe': ('Waiting for you', 'بانتظارك'),
  'ce.ph.confirmed': ('Confirmed', 'مؤكد'),
  'ce.ph.expired': ('Expired', 'منتهٍ'),
  'ce.ph.declined': ('Declined', 'مرفوض'),
  'ce.ph.cancelled': ('Cancelled', 'ملغى'),
  'ce.ex.awaitingProfessional': (
    'The professional has not answered yet. You can cancel until they do.',
    'لم يجب المهني بعد. يمكنك الإلغاء حتى يجيب.',
  ),
  'ce.ex.awaitingMe': (
    'The professional says you worked together. Confirm it if that is right.',
    'يقول المهني إنكما عملتما معاً. أكّد ذلك إن كان صحيحاً.',
  ),
  'ce.ex.confirmed': (
    'Both sides confirmed. You can write a review while the window is open.',
    'أكد الطرفان. يمكنك كتابة تقييم ما دامت المدة مفتوحة.',
  ),
  'ce.ex.expired': (
    'The 14 days passed without an answer. Nothing was confirmed.',
    'مرت 14 يوماً دون إجابة. لم يتم تأكيد شيء.',
  ),
  'ce.ex.declined': (
    'The professional declined this request.',
    'رفض المهني هذا الطلب.',
  ),
  'ce.ex.cancelled': ('You cancelled this request.', 'ألغيت هذا الطلب.'),
  'ce.edge.duplicate.t': (
    'You already have an open request',
    'لديك طلب مفتوح بالفعل',
  ),
  'ce.edge.duplicate.b': (
    'There is already an open engagement with this professional.',
    'يوجد ارتباط مفتوح مع هذا المهني بالفعل.',
  ),
  'ce.edge.duplicate.cta': ('Open it', 'افتحه'),
  'ce.edge.ineligible.t': (
    'This request is not allowed',
    'هذا الطلب غير مسموح',
  ),
  'ce.edge.ineligible.b': (
    'The service did not allow this engagement.',
    'لم تسمح الخدمة بهذا الارتباط.',
  ),
  'ce.edge.relatedAccount.t': (
    'Related accounts cannot engage',
    'لا يمكن للحسابات المرتبطة الارتباط',
  ),
  'ce.edge.relatedAccount.b': (
    'An account related to this professional cannot create an engagement.',
    'لا يمكن لحساب مرتبط بهذا المهني إنشاء ارتباط.',
  ),
  'ce.edge.professionalUnavailable.t': (
    'This professional is unavailable',
    'هذا المهني غير متاح',
  ),
  'ce.edge.professionalUnavailable.b': (
    'They cannot receive engagement requests right now.',
    'لا يمكنه استقبال طلبات الارتباط حالياً.',
  ),
  'ce.edge.error.t': ('We could not send the request', 'تعذّر إرسال الطلب'),
  'ce.edge.error.b': (
    'Nothing was sent. You can try again.',
    'لم يُرسل شيء. يمكنك المحاولة مجدداً.',
  ),
  'ce.edge.back': ('Back', 'رجوع'),
  'ce.edge.retry': ('Try again', 'حاول مجدداً'),
  'ce.signin.t': ('Log in to continue', 'سجّل الدخول للمتابعة'),

  // ---- reviews
  'rv.row': ('Your reviews', 'تقييماتك'),
  'rv.write.title': ('Write a review', 'اكتب تقييماً'),
  'rv.write.sub': ('About {name}', 'عن {name}'),
  'rv.stars': ('Your rating', 'تقييمك'),
  'rv.star': ('{n} of 5 stars', '{n} من 5 نجوم'),
  'rv.comment': ('Your review', 'تقييمك'),
  'rv.comment.hint': (
    'What was it like to work with them? 10 to 500 characters.',
    'كيف كانت تجربة العمل معهم؟ من 10 إلى 500 حرف.',
  ),
  'rv.count': ('{n} / 500', '{n} / 500'),
  'rv.err.rating': (
    'Choose a rating from 1 to 5 stars.',
    'اختر تقييماً من 1 إلى 5 نجوم.',
  ),
  'rv.err.short': ('Write at least 10 characters.', 'اكتب 10 أحرف على الأقل.'),
  'rv.err.long': ('Keep it to 500 characters.', 'اجعله ضمن 500 حرف.'),
  'rv.preview': ('Review it', 'راجعه'),
  'rv.preview.title': ('Check your review', 'تحقق من تقييمك'),
  'rv.preview.note': (
    'A reviewer checks every review before it is public. You can edit it later only if the service allows it.',
    'يراجع مراجع كل تقييم قبل نشره. يمكنك تعديله لاحقاً فقط إن سمحت الخدمة.',
  ),
  'rv.preview.edit': ('Go back and edit', 'عودة وتعديل'),
  'rv.submit': ('Submit review', 'إرسال التقييم'),
  'rv.window': ('You can review until {d}.', 'يمكنك التقييم حتى {d}.'),
  'rv.fail': (
    'We could not send your review. Nothing was submitted. Your text is still here.',
    'تعذّر إرسال تقييمك. لم يُرسل شيء. نصك ما زال هنا.',
  ),
  'rv.notEligible.fail': (
    'The service says you cannot review this yet.',
    'تقول الخدمة إنه لا يمكنك تقييم هذا بعد.',
  ),
  'rv.sent.t': ('Review sent for checking', 'أُرسل التقييم للمراجعة'),
  'rv.sent.b': (
    'It is not public yet. A reviewer checks it first.',
    'ليس منشوراً بعد. يراجعه مراجع أولاً.',
  ),
  'rv.st.pendingModeration': ('Being checked', 'قيد الفحص'),
  'rv.st.published': ('Published', 'منشور'),
  'rv.st.underReview': ('Reported, under review', 'مُبلَّغ عنه، قيد المراجعة'),
  'rv.st.removed': ('Removed', 'محذوف'),
  'rv.st.rejected': ('Not published', 'غير منشور'),
  'rv.ex.pendingModeration': (
    'A reviewer has not decided yet.',
    'لم يقرر المراجع بعد.',
  ),
  'rv.ex.published': ('Your review is public.', 'تقييمك منشور.'),
  'rv.ex.underReview': (
    'Someone reported this review. A reviewer is looking at it.',
    'أبلغ أحدهم عن هذا التقييم. يراجعه مراجع.',
  ),
  'rv.ex.removed': (
    'A reviewer removed this review.',
    'أزال مراجع هذا التقييم.',
  ),
  'rv.ex.rejected': (
    'A reviewer did not publish this review.',
    'لم ينشر المراجع هذا التقييم.',
  ),
  'rv.existing.t': ('You already reviewed this', 'قيّمت هذا من قبل'),
  'rv.edit': ('Edit your review', 'عدّل تقييمك'),
  'rv.edit.locked': (
    'You can edit it after a later interaction with this business.',
    'يمكنك تعديله بعد تفاعل لاحق مع هذا النشاط.',
  ),
  'rv.edit.sent': ('Edit sent for checking', 'أُرسل التعديل للمراجعة'),
  'rv.notYet.t': ('Not yet', 'ليس بعد'),
  'rv.notYet.b': (
    'You can review once the professional confirms you worked together.',
    'يمكنك التقييم عندما يؤكد المهني أنكما عملتما معاً.',
  ),
  'rv.notEligible.t': (
    'Reviews need a confirmed engagement',
    'التقييمات تتطلب ارتباطاً مؤكداً',
  ),
  'rv.notEligible.b': (
    'Request an engagement first. When both of you confirm, you can write a review.',
    'اطلب ارتباطاً أولاً. عندما تؤكدان معاً يمكنك كتابة تقييم.',
  ),
  'rv.expired.t': ('The review window has closed', 'انتهت مدة التقييم'),
  'rv.expired.b': (
    'A review can be written within 60 days of the confirmation.',
    'يمكن كتابة التقييم خلال 60 يوماً من التأكيد.',
  ),
  'rv.signin.t': ('Log in to write a review', 'سجّل الدخول لكتابة تقييم'),
  'rv.mine.title': ('Your reviews', 'تقييماتك'),
  'rv.mine.empty.t': ('No reviews yet', 'لا توجد تقييمات بعد'),
  'rv.mine.empty.b': (
    'Reviews you write appear here with their status.',
    'تظهر هنا التقييمات التي تكتبها مع حالتها.',
  ),
  'rv.mine.error': ('We could not load your reviews.', 'تعذّر تحميل تقييماتك.'),
  'rv.cta.engage': ('Request an engagement', 'اطلب ارتباطاً مهنياً'),
  'rv.back': ('Back', 'رجوع'),

  // ---- reporting
  'rp.action': ('Report review', 'الإبلاغ عن تقييم'),
  'rp.title': ('Report this review', 'أبلغ عن هذا التقييم'),
  'rp.sub': (
    'Tell us what is wrong. A reviewer will look at it.',
    'أخبرنا ما المشكلة. سيراجعه مراجع.',
  ),
  'rp.reason': ('Reason', 'السبب'),
  'rp.r.inappropriate': ('Inappropriate language', 'لغة غير لائقة'),
  'rp.r.falseMisleading': ('False or misleading', 'غير صحيح أو مضلل'),
  'rp.r.harassment': ('Harassment', 'مضايقة'),
  'rp.r.personalDetails': ('Shares personal details', 'يكشف بيانات شخصية'),
  'rp.r.notRelevant': ('Not about this business', 'ليس عن هذا النشاط'),
  'rp.r.other': ('Something else', 'سبب آخر'),
  'rp.note': ('Note (optional)', 'ملاحظة (اختياري)'),
  'rp.send': ('Send report', 'إرسال البلاغ'),
  'rp.err.reason': ('Choose a reason.', 'اختر سبباً.'),
  'rp.sent.t': ('Report sent', 'أُرسل البلاغ'),
  'rp.sent.b': (
    'A reviewer will look at this review. Nothing changes until they decide.',
    'سيراجع مراجع هذا التقييم. لا يتغير شيء حتى يقرر.',
  ),
  'rp.already': (
    'You already reported this review.',
    'أبلغت عن هذا التقييم من قبل.',
  ),
  'rp.fail': (
    'We could not send the report. Nothing was sent. Try again.',
    'تعذّر إرسال البلاغ. لم يُرسل شيء. حاول مجدداً.',
  ),
  'rp.close': ('Close', 'إغلاق'),
  'rv.demo': (
    'Demo: no review service is connected. Nothing here is published.',
    'تجريبي: لا توجد خدمة تقييمات متصلة. لا شيء هنا منشور.',
  ),
};
