using AdminService as service from '../../srv/admin-service';

annotate service.EmployeeCertifications with @(
    UI.LineItem       : [
        {Value: employee.name},
        {Value: certificate.code},
        {Value: certificate.name},
        {Value: status},
        {Value: earnedOn},
        {
            $Type: 'UI.DataFieldWithUrl',
            Value: evidenceUrl,
            Url  : evidenceUrl
        },
        {Value: validUntil},
    ],

    UI.SelectionFields: [
        status,
        earnedOn,
    ],
);
