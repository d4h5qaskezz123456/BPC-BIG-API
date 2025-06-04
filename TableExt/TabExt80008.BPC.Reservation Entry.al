tableextension 80008 "BPC.Reservation Entry" extends "Reservation Entry"
{
    fields
    {


    }
    procedure GetEntryNo() EntryNo: Integer
    var
        myInt: Integer;
    begin
        ReservationEntry.Reset();
        ReservationEntry.SetCurrentKey("Entry No.", Positive);
        if ReservationEntry.FindSet() then
            EntryNo := ReservationEntry."Entry No." + 1
        else
            EntryNo := 1;
        exit(EntryNo);
    end;

    var
        ReservationEntry: Record "Reservation Entry";
}