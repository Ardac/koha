ALTER TABLE subscription ADD COLUMN closed char(1);

UPDATE subscription SET closed = 'N';
