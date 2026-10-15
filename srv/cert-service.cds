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

}
