using {cert.manager as my} from '../db/schema';

@requires: 'admin'
service AdminService {
    entity Employees              as projection on my.Employees;

    @readonly
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

}
