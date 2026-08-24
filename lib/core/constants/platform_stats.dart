/// Platform-wide figures shown to parents who have not posted yet.
///
/// These are marketing copy, not data. **No API serves platform counts** — every
/// count endpoint on the backend is behind an admin permission — so these are
/// transcribed from the website and must be changed here when the website
/// changes, or the two will drift.
///
/// Sources, both parent-facing:
///   THTPRO/frontend/src/views/ParentLanding.jsx:92-96
///   THTPRO/frontend/src/components/home/HeroWithForm.jsx:153-167
///
/// Note the website is not internally consistent — its SEO landing pages claim
/// 1,100+ tutors against the 5,000+ used here, and "14,000+ students" from the
/// design mockup appears nowhere at all. When in doubt, match ParentLanding:
/// it is the page a parent actually arrives on.
///
/// Held as strings, not numbers, because they are claims with a shape ("5,000+",
/// "4.8/5") rather than quantities anything computes with.
abstract final class PlatformStats {
  static const String verifiedTutors = '5,000+';
  static const String verifiedTutorsLabel = 'Verified tutors';

  static const String studentsHelped = '12,000+';
  static const String studentsHelpedLabel = 'Students helped';

  static const String averageRating = '4.8/5';
  static const String averageRatingLabel = 'Average rating';
}
