using {cert.manager as my} from '../db/schema';

@requires: 'admin'
service AdminService {
    // Employees are edited with draft and never deleted (set active = false instead)
    @odata.draft.enabled
    @Capabilities.DeleteRestrictions.Deletable: false
    entity Employees              as projection on my.Employees;

    @odata.draft.enabled
    @Capabilities.DeleteRestrictions.Deletable: false
    entity Certifications         as projection on my.Certifications;

    @readonly
    entity EmployeeCertifications as projection on my.EmployeeCertifications
        actions {
            action approve() returns EmployeeCertifications;
            action reject()  returns EmployeeCertifications;
            action revoke()  returns EmployeeCertifications;
        };


    @readonly
    entity Statuses               as projection on my.Statuses;

    // Actions for AI assistants (unbound, so MCP offers them through "call"). Admin only.

    /** Approve a Pending certification: it becomes Verified. */
    action approveCertification(
                                /** Login name of the employee, e.g. erik */
                                userID: String,
                                /** SAP exam code, e.g. C_SAC */
                                code: String) returns EmployeeCertifications;

    /** Reject a Pending certification: it becomes Rejected. */
    action rejectCertification(
                               /** Login name of the employee, e.g. erik */
                               userID: String,
                               /** SAP exam code, e.g. C_SAC */
                               code: String)  returns EmployeeCertifications;

    /** Undo a decision: a Verified or Rejected certification goes back to Pending. */
    action revokeCertification(
                               /** Login name of the employee, e.g. erik */
                               userID: String,
                               /** SAP exam code, e.g. C_SAC */
                               code: String)  returns EmployeeCertifications;
}
