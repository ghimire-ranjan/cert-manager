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
                'CREATE'
            ],
            to   : 'authenticated-user',
            where: 'employee.userID = $user'
        },

        //only allow edit to certain statues 
        {
            grant: 'UPDATE',
            to   : 'authenticated-user',
            where: 'employee.userID = $user and (status = ''Planned'' or status = ''LearningJourney'' or status = ''Pending'')'

        },

        //only allow manger to read except with status reject
    
        {
            grant: 'READ',
            to   : 'authenticated-user',
            where: 'employee.manager.userID = $user and status <> ''Rejected'''
        },
        {
            grant: 'DELETE',
            to   : 'authenticated-user',
            where: 'employee.userID = $user and (status = ''Planned'' or status = ''LearningJourney''  or status = ''Pending'')'
        },
        {
            grant: '*',
            to   : 'admin'
        }
    ]
    entity EmployeeCertifications as projection on my.EmployeeCertifications;
}
