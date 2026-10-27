using {cert.manager as my} from '../db/schema';


@requires: ['employee', 'admin']
service CertService {

    @restrict: [
        {
            grant: 'READ',
            to   : 'authenticated-user'
        },

        {
            grant: '*',
            to   : 'admin'
        }
    ]
    entity Certifications         as projection on my.Certifications;

    @restrict: [
        {
            grant: 'READ',
            to   : 'authenticated-user'
        },
        {
            grant: '*',
            to   : 'admin'
        }
    ]
    // No 'certifications' link here: through it, anyone could $expand other people's records
    entity Employees              as projection on my.Employees excluding { certifications };

    @restrict: [
        {
            grant: [
                'READ',
                'CREATE'
            ],
            to   : 'authenticated-user',
            where: 'employee.userID = $user'
        },

        //only allow edit to certain statues
        {
            grant: 'UPDATE',
            to   : 'authenticated-user',
            where: 'employee.userID = $user and (status_code  = ''Planned'' or status_code  = ''LearningJourney'' or status_code  = ''Pending'')'

        },

        //only allow manger to read except with status_code  reject

        {
            grant: 'READ',
            to   : 'authenticated-user',
            where: 'employee.manager.userID = $user and status_code  <> ''Rejected'''
        },
        {
            grant: 'DELETE',
            to   : 'authenticated-user',
            where: 'employee.userID = $user and (status_code  = ''Planned'' or status_code  = ''LearningJourney''  or status_code  = ''Pending'')'
        },
        {
            grant: '*',
            to   : 'admin'
        }
    ]
    @odata.draft.enabled
    entity EmployeeCertifications as projection on my.EmployeeCertifications;


    @readonly
    entity Statuses               as projection on my.Statuses;



    // Actions for AI assistants. Unbound (not tied to one record), so the MCP plugin
   

    /** Plan to take a certification exam: creates a Planned record for the logged-in employee. */
    action planCertification(
        /** SAP exam code, e.g. C_FIORD */
        code       : String,
        /** Target date for passing the exam, e.g. 2027-03-01 */
        plannedFor : Date
    ) returns EmployeeCertifications;

    /** Record a passed exam for the logged-in employee. Updates their Planned or
        LearningJourney record for this code if there is one, otherwise creates a new one.
        The record becomes Pending (waiting for admin review); validUntil is set automatically. */
    action submitCertification(
        /** SAP exam code, e.g. C_SAC */
        code        : String,
        /** Date the exam was passed, e.g. 2026-10-10 */
        earnedOn    : Date,
        /** Link to proof, e.g. a Credly badge; must start with https:// */
        evidenceUrl : String
    ) returns EmployeeCertifications;

}
