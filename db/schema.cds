namespace cert.manager;

using {
    cuid,
    managed
} from '@sap/cds/common';

type Status : String(20) enum {
    Planned;
    LearningJourney;
    Pending;
    Verified;
    Rejected;
}

entity Certifications : cuid, managed {
    code        : String(20)  @mandatory;
    name        : String(100) @mandatory;
    issuer      : String(50);
    validMonths : Integer     @assert.range: [
        1,
        12
    ];
}

entity Employees : cuid, managed {
    userID  : String(50)  @mandatory;
    name    : String(100) @mandatory;
    email   : String(100);
    active  : Boolean default true;
    manager : Association to Employees;
}


entity EmployeeCertifications : cuid, managed {
    employee                  : Association to Employees      @mandatory;
    certificate               : Association to Certifications @mandatory;
    earnedOn                  : Date;
    plannedFor                : Date;
    validUntil                : Date;
    evidenceUrl               : String(500)                   @assert.format: '^https://';
    status                    : Status default 'Planned'      @assert.range;

    virtual daysUntilExpiry   : Integer;
    virtual expiryCriticality : Integer;
}
