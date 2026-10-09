using CertService as service from '../../srv/cert-service';

annotate service.EmployeeCertifications with @(
    UI.LineItem : [
        { Value : certificate.code, Label : 'Certificate' },
        { Value : certificate.name, Label : 'Name' },
        { Value : employee.name,    Label : 'Employee' },
        { Value : status,           Label : 'Status' },
        { Value : plannedFor,       Label : 'Planned For' },
        { Value : validUntil,       Label : 'Valid Until' },
        { Value : daysUntilExpiry,  Label : 'Days Left', Criticality : expiryCriticality },
    ]
);
