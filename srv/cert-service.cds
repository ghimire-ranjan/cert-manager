using {cert.manager as my} from '../db/schema';

service CertService {
    entity Certifications         as projection on my.Certifications;
    entity Employees              as projection on my.Employees;
    entity EmployeeCertifications as projection on my.EmployeeCertifications;
}
