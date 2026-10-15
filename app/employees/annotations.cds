using AdminService as service from '../../srv/admin-service';

annotate service.Employees with @(
    UI.HeaderInfo     : {
        TypeName      : '{i18n>EmployeeTypeName}',
        TypeNamePlural: '{i18n>EmployeeTypeNamePlural}',
        Title         : {Value: name},
        Description   : {Value: userID}
    },

    UI.LineItem       : [
        {Value: name},
        {Value: userID},
        {Value: email},
        {Value: manager_ID},
        {Value: active},
    ],

    UI.SelectionFields: [
        name,
        active,
        manager_ID,
    ],
);
