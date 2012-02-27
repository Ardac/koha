ALTER TABLE serial ADD COLUMN receiveddate date;

UPDATE TABLE serial SET receiveddate = planneddate WHERE status = 2;
