codeunit 80007 "BPC.Insert Member"
{
    TableNo = 80007;
    trigger OnRun()
    var
    begin
        InsertData(REC);
    end;

    local procedure InsertData(APITMPMemberContact: Record "BPC.TMP Member Contact" temporary)
    var

        LSCMemberAccount: Record "LSC Member Account";
        CheckLSCMemberAccount: Record "LSC Member Account";
    begin
        if not CheckLSCMemberAccount.Get('TEMPLATE') then
            CheckLSCMemberAccount.Init();

        LSCMemberAccount.Reset();
        LSCMemberAccount.SetRange("No.", APITMPMemberContact."BPC Account No.");
        if not LSCMemberAccount.FindSet() then begin
            LSCMemberAccount.Init();
            LSCMemberAccount."No." := APITMPMemberContact."BPC Account No.";
            LSCMemberAccount.Description := CopyStr(APITMPMemberContact."BPC Name", 1, 50);
            LSCMemberAccount."BPC.Description 2" := CopyStr(APITMPMemberContact."BPC Name", 51, 200);
            LSCMemberAccount.Validate("Club Code", CheckLSCMemberAccount."Club Code");
            LSCMemberAccount.Validate("Scheme Code", CheckLSCMemberAccount."Scheme Code");
            LSCMemberAccount."Account Type" := CheckLSCMemberAccount."Account Type";

            // LSCMemberAccount."Linked To Customer No." := APITMPMemberContact."BPC Account No.";
            LSCMemberAccount.Status := LSCMemberAccount.Status::Active;
            LSCMemberAccount.Insert();
            // InsertLSCMemberContact(APITMPMemberContact);
            // InsertLSCMembershipCard(APITMPMemberContact);
        end else begin
            LSCMemberAccount.Description := CopyStr(APITMPMemberContact."BPC Name", 1, 50);
            LSCMemberAccount."BPC.Description 2" := CopyStr(APITMPMemberContact."BPC Name", 51, 200);
            // LSCMemberAccount."Linked To Customer No." := APITMPMemberContact."BPC Account No.";
            //LSCMemberAccount.Status := LSCMemberAccount.Status::Active;
            LSCMemberAccount.Modify();
            // InsertLSCMemberContact(APITMPMemberContact);
            // InsertLSCMembershipCard(APITMPMemberContact);

        end;
        InsertLSCMemberContact(APITMPMemberContact, LSCMemberAccount);
        InsertLSCMembershipCard(APITMPMemberContact, LSCMemberAccount);
    end;



    local procedure InsertLSCMemberContact(APITMPMemberContact: Record "BPC.TMP Member Contact" temporary; pLSCMemberAccount: Record "LSC Member Account")
    var
        LSCMemberContact: Record "LSC Member Contact";
        Address1, Address2, Address3, AddressFull : Text;
        LenghtAdd1, LenghtAdd2, LenghtAdd3 : Integer;

        Name1, Name2, Name3, NameFull : Text;
        LenghtName1, LenghtName2, LenghtName3 : Integer;
    begin
        LSCMemberContact.Reset();
        LSCMemberContact.SetRange("Account No.", APITMPMemberContact."BPC Account No.");
        if not LSCMemberContact.FindSet() then begin
            LSCMemberContact.Init();
            LSCMemberContact."Account No." := APITMPMemberContact."BPC Account No.";
            LSCMemberContact."Contact No." := APITMPMemberContact."BPC Account No.";
            LSCMemberContact.Validate("Club Code", pLSCMemberAccount."Club Code");
            LSCMemberContact.Validate("Scheme Code", pLSCMemberAccount."Scheme Code");
            // LSCMemberContact.Name := CopyStr(APITMPMemberContact."BPC Name", 1, 100);
            // LSCMemberContact."Name 2" := CopyStr(APITMPMemberContact."BPC Name", 101, 150);
            // LSCMemberContact."BPC.Name 3" := CopyStr(APITMPMemberContact."BPC Name", 151, 200);
            // LSCMemberContact.Address := CopyStr(APITMPMemberContact."BPC Address", 1, 100);
            // LSCMemberContact."Address 2" := CopyStr(APITMPMemberContact."BPC Address", 101, 150);
            // LSCMemberContact."BPC.Address 3" := CopyStr(APITMPMemberContact."BPC Address", 151, 200);

            //Insert 20250314 by NM >>>
            //Name >>>
            Name1 := CopyStr(APITMPMemberContact."BPC Name", 1, 100);
            Name2 := CopyStr(APITMPMemberContact."BPC Name", 101, 150);
            Name3 := CopyStr(APITMPMemberContact."BPC Name", 151, 200);

            LenghtName1 := StrLen(Name1);
            LenghtName2 := StrLen(Name2);
            LenghtName3 := StrLen(Name3);

            if LenghtName1 > 100 then
                Name1 := CopyStr(Name1, 1, 100);

            if LenghtName2 > 50 then
                Name2 := CopyStr(Name2, 1, 50);

            if LenghtName3 > 50 then
                Name3 := CopyStr(Name3, 1, 50);

            LSCMemberContact.Name := Name1;
            LSCMemberContact."Name 2" := Name2;
            LSCMemberContact."BPC.Name 3" := Name3;
            //Name <<<

            //Address >>>
            AddressFull := APITMPMemberContact."BPC Address";
            Address1 := CopyStr(APITMPMemberContact."BPC Address", 1, 100);
            Address2 := CopyStr(APITMPMemberContact."BPC Address", 101, 150);
            Address3 := CopyStr(APITMPMemberContact."BPC Address", 151, 200);

            LenghtAdd1 := StrLen(Address1);
            LenghtAdd2 := StrLen(Address2);
            LenghtAdd3 := StrLen(Address3);

            if LenghtAdd1 > 100 then
                Address1 := CopyStr(Address1, 1, 100);

            if LenghtAdd2 > 50 then
                Address2 := CopyStr(Address2, 1, 50);

            if LenghtAdd3 > 50 then
                Address3 := CopyStr(Address3, 1, 50);

            LSCMemberContact.Address := Address1;
            LSCMemberContact."Address 2" := Address2;
            LSCMemberContact."BPC.Address 3" := Address3;
            //Address <<<
            //Insert 20250314 by NM <<<


            LSCMemberContact."Main Contact" := true;
            InsertPostCode(APITMPMemberContact."BPC City", APITMPMemberContact."BPC Post Code");

            LSCMemberContact.City := APITMPMemberContact."BPC City";
            LSCMemberContact."Post Code" := APITMPMemberContact."BPC Post Code";
            LSCMemberContact."BPC.VAT Registration No." := APITMPMemberContact."BPC VAT Registration No.";
            LSCMemberContact."Mobile Phone No." := APITMPMemberContact."BPC Mobile Phone No.";
            LSCMemberContact."Phone No." := APITMPMemberContact."BPC Phone No.";
            LSCMemberContact."E-Mail" := APITMPMemberContact."BPC E-Mail";
            LSCMemberContact."Date of Birth" := ConvertDate(APITMPMemberContact."BPC Date of Birth");
            if APITMPMemberContact."BPC Gender" = 'Male' then
                LSCMemberContact.Gender := LSCMemberContact.Gender::Male
            else if APITMPMemberContact."BPC Gender" = 'Female' then
                LSCMemberContact.Gender := LSCMemberContact.Gender::Female
            else if APITMPMemberContact."BPC Gender" = '' then
                LSCMemberContact.Gender := LSCMemberContact.Gender::" ";
            LSCMemberContact.Insert();
        end else begin
            // LSCMemberContact.Name := CopyStr(APITMPMemberContact."BPC Name", 1, 100);
            // LSCMemberContact."Name 2" := CopyStr(APITMPMemberContact."BPC Name", 101, 150);
            // LSCMemberContact."BPC.Name 3" := CopyStr(APITMPMemberContact."BPC Name", 151, 200);
            // LSCMemberContact.Address := CopyStr(APITMPMemberContact."BPC Address", 1, 100);
            // LSCMemberContact."Address 2" := CopyStr(APITMPMemberContact."BPC Address", 101, 150);
            // LSCMemberContact."BPC.Address 3" := CopyStr(APITMPMemberContact."BPC Address", 151, 200);

            //Insert 20250314 by NM >>>
            //Name >>>
            Name1 := CopyStr(APITMPMemberContact."BPC Name", 1, 100);
            Name2 := CopyStr(APITMPMemberContact."BPC Name", 101, 150);
            Name3 := CopyStr(APITMPMemberContact."BPC Name", 151, 200);

            LenghtName1 := StrLen(Name1);
            LenghtName2 := StrLen(Name2);
            LenghtName3 := StrLen(Name3);

            if LenghtName1 > 100 then
                Name1 := CopyStr(Name1, 1, 100);

            if LenghtName2 > 50 then
                Name2 := CopyStr(Name2, 1, 50);

            if LenghtName3 > 50 then
                Name3 := CopyStr(Name3, 1, 50);

            LSCMemberContact.Name := Name1;
            LSCMemberContact."Name 2" := Name2;
            LSCMemberContact."BPC.Name 3" := Name3;
            //Name <<<

            //Address >>>
            AddressFull := APITMPMemberContact."BPC Address";
            Address1 := CopyStr(APITMPMemberContact."BPC Address", 1, 100);
            Address2 := CopyStr(APITMPMemberContact."BPC Address", 101, 150);
            Address3 := CopyStr(APITMPMemberContact."BPC Address", 151, 200);

            LenghtAdd1 := StrLen(Address1);
            LenghtAdd2 := StrLen(Address2);
            LenghtAdd3 := StrLen(Address3);

            if LenghtAdd1 > 100 then
                Address1 := CopyStr(Address1, 1, 100);

            if LenghtAdd2 > 50 then
                Address2 := CopyStr(Address2, 1, 50);

            if LenghtAdd3 > 50 then
                Address3 := CopyStr(Address3, 1, 50);

            LSCMemberContact.Address := Address1;
            LSCMemberContact."Address 2" := Address2;
            LSCMemberContact."BPC.Address 3" := Address3;
            //Address <<<
            //Insert 20250314 by NM <<<

            InsertPostCode(APITMPMemberContact."BPC City", APITMPMemberContact."BPC Post Code");

            LSCMemberContact.City := APITMPMemberContact."BPC City";
            LSCMemberContact."Post Code" := APITMPMemberContact."BPC Post Code";
            LSCMemberContact."BPC.VAT Registration No." := APITMPMemberContact."BPC VAT Registration No.";
            LSCMemberContact."Mobile Phone No." := APITMPMemberContact."BPC Mobile Phone No.";
            LSCMemberContact."Phone No." := APITMPMemberContact."BPC Phone No.";
            LSCMemberContact."E-Mail" := APITMPMemberContact."BPC E-Mail";
            LSCMemberContact."Date of Birth" := ConvertDate(APITMPMemberContact."BPC Date of Birth");
            if APITMPMemberContact."BPC Gender" = 'Male' then
                LSCMemberContact.Gender := LSCMemberContact.Gender::Male
            else if APITMPMemberContact."BPC Gender" = 'Female' then
                LSCMemberContact.Gender := LSCMemberContact.Gender::Female
            else if APITMPMemberContact."BPC Gender" = '' then
                LSCMemberContact.Gender := LSCMemberContact.Gender::" ";
            LSCMemberContact.Modify();
        end;

    end;

    local procedure InsertLSCMembershipCard(APITMPMemberContact: Record "BPC.TMP Member Contact" temporary; pLSCMemberAccount: Record "LSC Member Account")
    var
        LSCMembershipCard: Record "LSC Membership Card";
        CheckLSCMemberAccount: Record "LSC Member Account";
    begin
        if not CheckLSCMemberAccount.Get('TEMPLATE') then
            CheckLSCMemberAccount.Init();

        LSCMembershipCard.Reset();
        LSCMembershipCard.SetRange("Card No.", APITMPMemberContact."BPC Account No.");
        if not LSCMembershipCard.FindSet() then begin
            LSCMembershipCard.Init();
            LSCMembershipCard."Card No." := APITMPMemberContact."BPC Account No.";
            LSCMembershipCard."Club Code" := pLSCMemberAccount."Club Code";
            LSCMembershipCard."Scheme Code" := pLSCMemberAccount."Scheme Code";
            LSCMembershipCard."Account No." := APITMPMemberContact."BPC Account No.";
            LSCMembershipCard."Contact No." := APITMPMemberContact."BPC Account No.";
            LSCMembershipCard."Linked to Account" := true;
            LSCMembershipCard.Status := LSCMembershipCard.Status::Active;
            LSCMembershipCard.Insert();
        end;
    end;

    local procedure InsertPostCode(pCity: Text[30]; pPostCode: Text[30])
    var
        PostCode: Record "Post Code";
    begin
        PostCode.Reset();
        PostCode.SetRange(Code, pPostCode);
        PostCode.SetRange(City, pCity);
        if not PostCode.FindSet() then begin
            PostCode.Init();
            PostCode.Code := pPostCode;
            PostCode.City := pCity;
            PostCode.Insert();
        end;
    end;

    local procedure InsertCustomer(pAPITMPMemberContact: Record "BPC.TMP Member Contact")
    var
        Customer: Record Customer;
        Address1, Address2, Address3, AddressFull : Text;
        LenghtAdd1, LenghtAdd2, LenghtAdd3 : Integer;

        Name1, Name2, Name3, NameFull : Text;
        LenghtName1, LenghtName2, LenghtName3 : Integer;
    begin
        Customer.Reset();
        Customer.SetRange("No.", pAPITMPMemberContact."BPC Account No.");
        if not Customer.FindSet() then begin
            Customer.Init();
            Customer."No." := pAPITMPMemberContact."BPC Account No.";
            // Customer.Name := CopyStr(pAPITMPMemberContact."BPC Name", 1, 100);
            // Customer."Name 2" := CopyStr(pAPITMPMemberContact."BPC Name", 101, 150);
            // Customer."BPC.Name 3" := CopyStr(pAPITMPMemberContact."BPC Name", 151, 200);
            // Customer.Address := CopyStr(pAPITMPMemberContact."BPC Address", 1, 100);
            // Customer."Address 2" := CopyStr(pAPITMPMemberContact."BPC Address", 101, 150);
            // Customer."BPC.Address 3" := CopyStr(pAPITMPMemberContact."BPC Address", 151, 200);


            //Insert 20250314 by NM >>>
            //Name >>>
            Name1 := CopyStr(pAPITMPMemberContact."BPC Name", 1, 100);
            Name2 := CopyStr(pAPITMPMemberContact."BPC Name", 101, 150);
            Name3 := CopyStr(pAPITMPMemberContact."BPC Name", 151, 200);

            LenghtName1 := StrLen(Name1);
            LenghtName2 := StrLen(Name2);
            LenghtName3 := StrLen(Name3);

            if LenghtName1 > 100 then
                Name1 := CopyStr(Name1, 1, 100);

            if LenghtName2 > 50 then
                Name2 := CopyStr(Name2, 1, 50);

            if LenghtName3 > 50 then
                Name3 := CopyStr(Name3, 1, 50);

            Customer.Name := Name1;
            Customer."Name 2" := Name2;
            Customer."BPC.Name 3" := Name3;
            //Name <<<

            //Address >>>
            AddressFull := pAPITMPMemberContact."BPC Address";
            Address1 := CopyStr(pAPITMPMemberContact."BPC Address", 1, 100);
            Address2 := CopyStr(pAPITMPMemberContact."BPC Address", 101, 150);
            Address3 := CopyStr(pAPITMPMemberContact."BPC Address", 151, 200);

            LenghtAdd1 := StrLen(Address1);
            LenghtAdd2 := StrLen(Address2);
            LenghtAdd3 := StrLen(Address3);

            if LenghtAdd1 > 100 then
                Address1 := CopyStr(Address1, 1, 100);

            if LenghtAdd2 > 50 then
                Address2 := CopyStr(Address2, 1, 50);

            if LenghtAdd3 > 50 then
                Address3 := CopyStr(Address3, 1, 50);

            Customer.Address := Address1;
            Customer."Address 2" := Address2;
            Customer."BPC.Address 3" := Address3;
            //Address <<<
            //Insert 20250314 by NM <<<

            InsertPostCode(pAPITMPMemberContact."BPC City", pAPITMPMemberContact."BPC Post Code");

            Customer.City := pAPITMPMemberContact."BPC City";
            Customer."Post Code" := pAPITMPMemberContact."BPC Post Code";
            Customer."VAT Registration No." := pAPITMPMemberContact."BPC VAT Registration No.";
            Customer."Mobile Phone No." := pAPITMPMemberContact."BPC Mobile Phone No.";
            Customer."Phone No." := pAPITMPMemberContact."BPC Phone No.";
            Customer."E-Mail" := pAPITMPMemberContact."BPC E-Mail";
            Customer.Insert();
        end
        // else begin
        //     Customer."No." := pAPITMPMemberContact."BPC Account No.";
        //     Customer.Name := CopyStr(pAPITMPMemberContact."BPC Name", 1, 100);
        //     Customer."Name 2" := CopyStr(pAPITMPMemberContact."BPC Name", 101, 150);
        //     Customer."BPC.Name 3" := CopyStr(pAPITMPMemberContact."BPC Name", 151, 200);
        //     Customer.Address := CopyStr(pAPITMPMemberContact."BPC Address", 1, 100);
        //     Customer."Address 2" := CopyStr(pAPITMPMemberContact."BPC Address", 101, 150);
        //     Customer."BPC.Address 3" := CopyStr(pAPITMPMemberContact."BPC Address", 151, 200);
        //     InsertPostCode(pAPITMPMemberContact."BPC City", pAPITMPMemberContact."BPC Post Code");

        //     Customer.City := pAPITMPMemberContact."BPC City";
        //     Customer."Post Code" := pAPITMPMemberContact."BPC Post Code";
        //     Customer."VAT Registration No." := pAPITMPMemberContact."BPC VAT Registration No.";
        //     Customer."Mobile Phone No." := pAPITMPMemberContact."BPC Mobile Phone No.";
        //     Customer."Phone No." := pAPITMPMemberContact."BPC Phone No.";
        //     Customer."E-Mail" := pAPITMPMemberContact."BPC E-Mail";
        //     Customer.Modify();
        // end;
    end;

    local procedure ConvertDate(pTxtDate: Text): Date
    var
        DD: Integer;
        MM: Integer;
        YYYY: Integer;
    begin
        if pTxtDate <> '' then begin
            Evaluate(DD, CopyStr(pTxtDate, 1, 2));
            Evaluate(MM, CopyStr(pTxtDate, 4, 2));
            Evaluate(YYYY, CopyStr(pTxtDate, 7, 4));
            exit(DMY2Date(DD, MM, YYYY));
        end;
    end;

}