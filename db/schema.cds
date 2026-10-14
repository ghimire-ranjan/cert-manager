namespace cert.manager;

using {
    cuid,
    managed,
    sap
} from '@sap/cds/common';

entity Statuses : sap.common.CodeList {
    key code : String(20);
}


entity Certifications : cuid, managed {
    code   : String(20)  @mandatory;
    name   : String(100) @mandatory;
    issuer : String(50);
}

entity Employees : cuid, managed {
    userID  : String(50)  @mandatory;
    name    : String(100) @mandatory;
    email   : String(100);
    active  : Boolean default true;
    manager : Association to Employees;
}


entity EmployeeCertifications : cuid, managed {
    employee                  : Association to Employees                  @mandatory;
    certificate               : Association to Certifications             @mandatory;
    earnedOn                  : Date;
    plannedFor                : Date;
    isEarned                  : Boolean = (
        earnedOn is not null
    );
    validUntil                : Date                                      @readonly;
    evidenceUrl               : String(500)                               @assert.format: '^https://';
    status                    : Association to Statuses default 'Planned' @assert.target;


    virtual daysUntilExpiry   : Integer                                   @readonly;
    virtual expiryCriticality : Integer                                   @readonly;
}
