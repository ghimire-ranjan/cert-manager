using {cert.manager as my} from '../db/schema';

// Labels on the database entities, so every service and app gets them
annotate my.EmployeeCertifications with {
    certificate       @Common.Label: '{i18n>Certificate}';
    employee          @Common.Label: '{i18n>Employee}';
    status            @Common.Label          : '{i18n>Status}'
                      @Common.Text           : status.name
                      @Common.TextArrangement: #TextOnly
                      @Common.ValueListWithFixedValues;

    earnedOn          @Common.Label: '{i18n>EarnedOn}';
    plannedFor        @Common.Label: '{i18n>PlannedFor}';
    validUntil        @Common.Label: '{i18n>ValidUntil}';
    isEarned          @Common.Label: '{i18n>IsEarned}';
    evidenceUrl       @Common.Label: '{i18n>EvidenceUrl}';
    daysUntilExpiry   @Common.Label: '{i18n>DaysLeft}';
    expiryCriticality @UI.Hidden;

};

annotate my.Certifications with {
    code   @Common.Label: '{i18n>CertCode}';
    name   @Common.Label: '{i18n>CertName}';
    issuer @Common.Label: '{i18n>Issuer}';
};

annotate my.Employees with {
    name @Common.Label: '{i18n>EmployeeName}';
};
