using {CertService} from './cert-service';

// Descriptions for AI assistants (MCP describe, A2A agent). Plain language, no logic.

/** Certifications held or planned by employees: one row = one employee + one certification.
    Users see only their own rows; managers also see their direct reports' rows (except Rejected);
    admins see all rows. */
annotate CertService.EmployeeCertifications with {
    /** Lifecycle: Planned or LearningJourney (not passed yet; plannedFor is the target date)
        -> Pending (passed, earnedOn filled in, waiting for admin review)
        -> Verified (approved by an admin) or Rejected. Employees cannot set Verified or Rejected. */
    status;
    /** Date the exam was passed. Empty while the certification is only planned. */
    earnedOn;
    /** Target date for passing the exam, used while the status is Planned or LearningJourney. */
    plannedFor;
    /** Expiry date: always earnedOn + 1 year (SAP certifications are valid for 12 months).
        Use this field to filter or sort by expiry. */
    validUntil;
    /** Days from today until validUntil; negative means already expired. Calculated when read,
        so it cannot be used in WHERE or ORDER BY: filter on validUntil instead. */
    daysUntilExpiry;
    /** Link to proof of the certification, e.g. a Credly badge. Must start with https://. */
    evidenceUrl;
    /** True when earnedOn is filled in. */
    isEarned;
};

/** Catalogue of SAP certifications that can be planned or earned. Everyone can read it;
    only admins can change it. */
annotate CertService.Certifications with {
    /** SAP exam code, e.g. C_CPE or C_FIORD. Unique per certification; use it to find one. */
    code;
    /** Full official name, e.g. "SAP Certified Associate - Backend Developer - SAP Cloud
        Application Programming Model". */
    name;
    /** Who issues the certification, e.g. SAP. */
    issuer;
};

/** People in the company. Everyone can read the list; only admins can change it. */
annotate CertService.Employees with {
    /** Login name of the employee, e.g. ranjan. Unique; the logged-in user is the employee
        whose userID matches the login. */
    userID;
    /** Full name, e.g. Ranjan Ghimire. */
    name;
    /** Work e-mail address. */
    email;
    /** False when the employee has left the company. Their certifications stay on record. */
    active;
    /** The person this employee reports to (their manager). Empty for the top of the
        organisation. A manager can read the certifications of their direct reports. */
    manager;
};
