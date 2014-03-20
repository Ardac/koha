CREATE TABLE illrequest (
    id serial primary key,
    borrowernumber integer references borrowers (borrowernumber),
    biblionumber integer references biblio (biblionumber),
    status varchar(50),
    placement_date date,
    reply_date date,
    ts timestamp default current_timestamp on update current_timestamp,
    completion_date date,
    reqtype varchar(30),
    branch varchar(50)
);

CREATE TABLE illreq_attribute (
    req_id references illrequest ( id ),
    attrtype varchar(30) not null,
    attrvalue text not null
);
