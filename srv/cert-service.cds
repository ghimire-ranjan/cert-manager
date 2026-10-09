using {cert.manager as my} from '../db/schema';


@requires: 'authenticated-user'
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
    entity Employees              as projection on my.Employees;

    @restrict: [
        {
            grant: [
                'READ',
                'CREATE',
                'UPDATE'
            ],
            to   : 'authenticated-user',
            where: 'employee.userID = $user'
        },
        {
            grant: 'READ',
            to   : 'authenticated-user',
            where: 'employee.manager.userID = $user'
        },
        {
            grant: 'DELETE',
            to   : 'authenticated-user',
            where: 'employee.userID = $user and (status = ''Planned'' or status = ''LearningJourney'')'
        },
        {
            grant: '*',
            to   : 'admin'
        }
    ]
    entity EmployeeCertifications as projection on my.EmployeeCertifications;
}
