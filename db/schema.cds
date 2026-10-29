namespace cert.manager;

using {
    cuid,
    managed,
    sap
} from '@sap/cds/common';

entity Statuses : sap.common.CodeList {
    key code : String(20);
}


@assert.unique: {code: [code]}
entity Certifications : cuid, managed {
    code   : String(20)  @mandatory;
    name   : String(100) @mandatory;
    issuer : String(50);
}

// userID is the login name, so no two employees may share it
@assert.unique: {userID: [userID]}
@assert.unique: {email: [email]}
entity Employees : cuid, managed {
    userID         : String(50)  ;
    name           : String(100) @mandatory;
    email          : String(100);
    active         : Boolean default true;
    manager        : Association to Employees;
    // All records of this employee (looks back along employee_ID, adds no column)
    certifications : Association to many EmployeeCertifications
                         on certifications.employee = $self;
}


entity EmployeeCertifications : cuid, managed {
    employee                  : Association to Employees                  @mandatory;
    certificate               : Association to Certifications             @mandatory;
    earnedOn                  : Date;
    plannedFor                : Date;
    // case instead of "earnedOn is not null": HANA allows a condition only in WHERE / CASE
    isEarned                  : Boolean = (
        case when earnedOn is not null then true else false end
    );
    validUntil                : Date                                      @readonly;
    evidenceUrl               : String(500)                               @assert.format: '^https://';
    status                    : Association to Statuses default 'Planned' @assert.target;


    virtual daysUntilExpiry   : Integer                                   @readonly;
    virtual expiryCriticality : Integer                                   @readonly;
}
