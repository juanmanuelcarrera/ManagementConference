/*
 * @author - Juan Manuel Carrera García
 */

DROP TABLE participante CASCADE CONSTRAINTS;
DROP TABLE asistente CASCADE CONSTRAINTS;
DROP TABLE autor CASCADE CONSTRAINTS;
DROP TABLE experto CASCADE CONSTRAINTS;
DROP TABLE sesion CASCADE CONSTRAINTS;
DROP TABLE articulo CASCADE CONSTRAINTS;
DROP TABLE escribe CASCADE CONSTRAINTS;
DROP TABLE evalua CASCADE CONSTRAINTS;
DROP TABLE conflicto CASCADE CONSTRAINTS;
DROP TABLE palabras CASCADE CONSTRAINTS;
DROP SEQUENCE nS;

CREATE SEQUENCE nS INCREMENT BY 1 START WITH 1;

CREATE TABLE participante 
(correo VARCHAR2 (25) PRIMARY KEY, 
nombre VARCHAR2 (25) NOT NULL,
pais VARCHAR2 (20) NOT NULL,
afilicacion VARCHAR2 (30) NOT NULL);

CREATE TABLE asistente 
(correo VARCHAR2 (25) PRIMARY KEY REFERENCES participante ON DELETE CASCADE,
tarifa VARCHAR2 (10) CHECK (tarifa = 'estudiante' OR tarifa = 'regular'),
n_socio NUMBER (10) NOT NULL,
tickets NUMBER (2) NOT NULL,
vegetariano VARCHAR (2) CHECK (vegetariano = 'si' OR vegetariano = 'no'));

CREATE TABLE autor
(correo VARCHAR2 (25) PRIMARY KEY REFERENCES participante ON DELETE CASCADE,
doctor VARCHAR2 (2));

CREATE TABLE experto
(correo VARCHAR2 (25) PRIMARY KEY REFERENCES participante ON DELETE CASCADE,
n_años NUMBER (2));

CREATE TABLE sesion 
(fecha DATE NOT NULL,
n_orden NUMBER (2) NOT NULL,
tituloS VARCHAR2 (20) NOT NULL,
correoS REFERENCES experto ON DELETE SET NULL,
CONSTRAINTS ses_pk PRIMARY KEY (fecha, n_orden));

CREATE TABLE articulo 
(numero NUMBER (5) PRIMARY KEY,
tituloA VARCHAR2 (60) NOT NULL,
resumen VARCHAR2 (150),
aceptado VARCHAR2 (2) DEFAULT 'No',
fecha DATE,
n_orden NUMBER (2),
CONSTRAINTS art_fk FOREIGN KEY (fecha, n_orden) REFERENCES sesion ON DELETE SET NULL);

CREATE TABLE palabras 
(numero NUMBER (5),
palabra VARCHAR2 (15),
CONSTRAINTS pal_fk FOREIGN KEY (numero) REFERENCES articulo ON DELETE CASCADE,
CONSTRAINTS pal_pk PRIMARY KEY (numero, palabra));

CREATE TABLE escribe 
(correo VARCHAR2 (25),
numero NUMBER (5),
CONSTRAINTS esc_pk PRIMARY KEY (correo, numero),
CONSTRAINTS esc_fk1 FOREIGN KEY (correo) REFERENCES autor ON DELETE CASCADE,
CONSTRAINTS esc_fk2 FOREIGN KEY (numero) REFERENCES articulo ON DELETE CASCADE);


CREATE TABLE evalua 
(correo VARCHAR2 (25),
numero NUMBER (5),
nota NUMBER (1) DEFAULT 0,
nivel_experto NUMBER (1) DEFAULT 0,
CONSTRAINTS ev_pk PRIMARY KEY (correo, numero),
CONSTRAINTS ev_fk1 FOREIGN KEY (correo) REFERENCES experto ON DELETE SET NULL,
CONSTRAINTS ev_fk2 FOREIGN KEY (numero) REFERENCES articulo ON DELETE CASCADE);


CREATE TABLE conflicto
(correo VARCHAR2 (25),
numero NUMBER (5),
CONSTRAINTS con_pk PRIMARY KEY (correo, numero),
CONSTRAINTS con_fk1 FOREIGN KEY (correo) REFERENCES experto ON DELETE CASCADE,
CONSTRAINTS con_fk2 FOREIGN KEY (numero) REFERENCES articulo ON DELETE CASCADE);


/*Procedimiento 3 
Implementar un procedimiento que presente la relación de los revisores que pueden moderar las diferentes sesiones del congreso. 
Para cada sesión (fecha y número de sesión) se indicarán el nombre de los revisores que están registrados como asistentes y que 
no tengan ningún artículo firmado por ellos en la sesión. El procedimiento deberá permitir indicar si los revisores deben 
restringirse tan solo a los que no tengan asignada ninguna otra sesión.*/
/
CREATE OR REPLACE 
PROCEDURE revisores_sesion (revisoresunicos boolean)
IS
  CURSOR caux IS SELECT fecha, n_orden, nombre 
                          FROM sesion s, (SELECT correo, nombre FROM (participante NATURAL JOIN asistente NATURAL JOIN experto)) e
                             WHERE e.correo NOT IN (SELECT DISTINCT correo FROM escribe 
                                                    NATURAL JOIN articulo NATURAL JOIN sesion 
                                                          WHERE fecha = s.fecha AND n_orden = s.n_orden)
                        ORDER BY fecha;
  
  CURSOR caux1 IS SELECT fecha, n_orden, nombre 
                          FROM sesion s, (SELECT correo, nombre FROM (participante NATURAL JOIN asistente NATURAL JOIN experto)) e
                             WHERE e.correo NOT IN ((SELECT DISTINCT correo FROM escribe 
                                                    NATURAL JOIN articulo NATURAL JOIN sesion 
                                                          WHERE fecha = s.fecha AND n_orden = s.n_orden) 
                                                          UNION (SELECT DISTINCT correoS correo FROM sesion WHERE
                                                                          correoS IS NOT NULL))
                        ORDER BY fecha;
  
  v_fe sesion.fecha%TYPE;
  v_nu sesion.n_orden%TYPE;
  tb constant VARCHAR2(1):=chr(9);
  BEGIN
    v_fe := to_date('01/01/0001','dd/mm/yyyy');
    v_nu := -1;
    dbms_output.put_line(rpad('Fecha',10,' ') || tb || rpad('Sesion',8,' ') || tb || rpad('Revisor',10,' '));
    dbms_output.put_line(rpad('-',33,'-'));
    IF revisoresunicos THEN 
      FOR raux IN caux1 loop
       IF v_fe != raux.fecha OR v_nu != raux.n_orden THEN
         dbms_output.put_line(rpad(raux.fecha,10,' ') || tb || rpad(raux.n_orden,8,' ') || tb || rpad(raux.nombre,15,' '));
         v_fe := raux.fecha;
         v_nu := raux.n_orden;
       ELSE
        dbms_output.put_line(rpad('',10,' ') || tb || rpad('',8,' ') || tb || rpad(raux.nombre,15,' '));
       END IF;
      END loop;
    ELSE
      FOR raux IN caux loop
        IF v_fe != raux.fecha OR v_nu != raux.n_orden THEN
         dbms_output.put_line(rpad(raux.fecha,10,' ') || tb || rpad(raux.n_orden,8,' ') || tb || rpad(raux.nombre,15,' '));
         v_fe := raux.fecha;
         v_nu := raux.n_orden;
       ELSE
         dbms_output.put_line(rpad('',10,' ') || tb || rpad('',8,' ') || tb || rpad(raux.nombre,15,' '));
       END IF;
      END loop; 
    END IF;
END revisores_sesion;


/*Procedimiento 4
Implementar un procedimiento que reciba como parámetros el importe de la tarifa de estudiante, la tarifa regular, 
el precio del ticket extra para la cena de gala y el descuento que se aplica a los socios de la institución organizadora y 
genere un listado con el nombre de cada asistente, el coste de cada concepto (tarifa, tickets y descuento de socio) y el total a pagar. 
Ordénalo por nombre de asistente.*/
/
CREATE OR REPLACE 
PROCEDURE lista_asistentes (tarifaes NUMBER, tarifare NUMBER, ticketpr NUMBER, descsocio NUMBER)
IS
  CURSOR caux IS SELECT nombre, correo, tarifa, tickets, n_socio FROM asistente NATURAL JOIN participante ORDER BY nombre;
  v_total NUMBER (6,2);
   v_extra NUMBER (6,2);
  tb constant VARCHAR2(1) := chr(9);
  BEGIN
  dbms_output.put_line(rpad('Nombre',15,' ') || tb || rpad('Tarifa',8,' ') || tb || rpad('Precio Extra',12,' ') || tb || rpad('Nº Socio',9,' ') || tb || rpad('Total',8,' '));
  dbms_output.put_line(rpad('-',66,'-'));
  FOR raux IN caux loop
    v_total := 0;
    v_extra := 0;
    IF raux.tarifa = 'estudiante' THEN
      IF raux.n_socio = 0 THEN 
        v_extra := raux.tickets * ticketpr;
        v_total := v_extra + tarifaes;
        dbms_output.put_line(rpad(raux.nombre,15,' ') || tb || rpad(tarifaes,8,' ') || tb || rpad(v_extra,12,' ') || tb || rpad(raux.n_socio,9,' ') || tb || rpad( v_total,8,' '));
      ELSE
        v_extra := raux.tickets * ticketpr;
        v_total := v_extra + (tarifaes - (tarifaes * (descsocio / 100)));   -- EL DESCUENTO LO HACEMOS SOBRE LA TARIFA
        dbms_output.put_line(rpad(raux.nombre,15,' ') || tb || rpad(tarifaes,8,' ') || tb || rpad(v_extra,12,' ') || tb || rpad(raux.n_socio,9,' ') || tb || rpad( v_total,8,' '));
      END IF;
   ELSE 
    IF raux.tarifa = 'regular' THEN
      IF raux.n_socio = 0 THEN 
        v_extra := raux.tickets * ticketpr;
        v_total := v_extra + tarifare;
        dbms_output.put_line(rpad(raux.nombre,15,' ') || tb || rpad(tarifare,8,' ') || tb || rpad(v_extra,12,' ') || tb || rpad(raux.n_socio,9,' ') || tb || rpad( v_total,8,' '));
      ELSE
         v_extra := raux.tickets * ticketpr;
         v_total := v_extra + (tarifare - (tarifare * (descsocio / 100)));    -- EL DESCUENTO LO HACEMOS SOBRE LA TARIFA
         dbms_output.put_line(rpad(raux.nombre,15,' ') || tb || rpad(tarifare,8,' ') || tb || rpad(v_extra,12,' ') || tb || rpad(raux.n_socio,9,' ') || tb || rpad( v_total,8,' '));
      END IF;
    END IF;
   END IF;
 END loop;
END;


/*Procedimiento 5
Implementar un procedimiento que reciba como parámetro un valor que establece la puntuación mínima que requiere un artículo 
para ser aceptado para su presentación en el congreso. Dicha puntuación se calcula sumando los productos de los puntos 
asignados por un revisor y su nivel de conocimiento y dividiendo el total por el número de revisores del artículo. 
De acuerdo a la puntuación obtenida y el límite establecido se actualizará la decisión del articulo como aceptado o rechazado. 
Así mismo el procedimiento mostrará la relación de los artículos (número y título), la puntuación obtenida y la decisión asignada.
*/
/
CREATE OR REPLACE 
PROCEDURE calcula_nota (notaminima NUMBER)
IS
  CURSOR caux IS SELECT numero, tituloA, (sum(nota * nivel_experto) / count (correo)) puntuacion FROM articulo NATURAL JOIN evalua
                        GROUP BY numero, tituloa
                        ORDER BY puntuacion DESC;
 tb constant VARCHAR2(1) := chr(9);
  BEGIN
    dbms_output.put_line(lpad('Numero',8,' ') || tb || rpad('Titulo',70,' ') || tb || lpad('Evaluación',12,' ') || tb || rpad('Decisión',10,' '));
    dbms_output.put_line(rpad('-',112,'-'));
    FOR raux IN caux loop
      IF raux.puntuacion > notaminima THEN
        dbms_output.put_line(lpad(raux.numero,8,' ') || tb || rpad(raux.tituloA,70,' ') || tb || lpad(raux.puntuacion,12,' ') || tb || rpad('ACCEPT',10,' '));
        UPDATE articulo SET aceptado = 'si' WHERE numero = raux.numero;
      ELSE
        dbms_output.put_line(lpad(raux.numero,8,' ') || tb || rpad(raux.tituloA,70,' ') || tb || lpad(raux.puntuacion,12,' ') || tb || rpad('REJECT',10,' '));
        UPDATE articulo SET aceptado = 'no' WHERE numero = raux.numero;
      END IF;
    END loop;    
END;
  
/*Implementar un trigger que cree un conflicto de interes cuando se registre un articulo en el que uno de los aurotores sea a su
vez revisor en la conferencia*/
/
create or replace 
trigger conflicto_interes after insert on escribe
for each row
--una vez para cada fila
  declare
    v_correo experto.correo%type;
    
   begin
     v_correo := null;
     select correo into v_correo from experto where correo = :new.correo;
     if v_correo is not null then
       insert into conflicto values (v_correo, :new.numero);
    end if;
    
    exception 
    when no_data_found then null;   
end;

/
INSERT INTO participante VALUES ('juan@gmail.com', 'Juan', 'España', 'Telefonica');
INSERT INTO participante VALUES ('antoniojimenez@yahoo.es', 'Toni', 'España', 'U.Alcala');
INSERT INTO participante VALUES ('abdul@gmail.com', 'Abdul', 'Marruecos', 'Royal Air Marroc');
INSERT INTO participante VALUES ('sergigil@ucm.es', 'Sergio', 'España', 'U.Complutense');
INSERT INTO participante VALUES ('ana_g@hotmail.es', 'Ana Maria', 'España', 'Santander');
INSERT INTO participante VALUES ('aleksandra.89@gmail.com', 'Aleksandra', 'Rusia', 'Orbital');
INSERT INTO participante VALUES ('bernadetta@gmail.com', 'Bernadetta', 'Italia', 'Ferrari');
INSERT INTO participante VALUES ('hélène@gmail.com', 'Hélène', 'Francia', 'Renault');
INSERT INTO participante VALUES ('nuriag@msn.es', 'Nuria', 'España', 'Ministerio De Defensa');
INSERT INTO participante VALUES ('arturo@gmail.com', 'Arturo', 'Francia', 'Crabtree');
INSERT INTO participante VALUES ('rodrigo@ucm.es', 'Rodrigo', 'España', 'U.Complutense');
INSERT INTO participante VALUES ('cjulia@yahoo.es', 'Julia', 'España', 'Metro');

INSERT INTO autor VALUES ('juan@gmail.com', 'Si');
INSERT INTO autor VALUES ('hélène@gmail.com', 'No');
INSERT INTO autor VALUES ('arturo@gmail.com', 'Si');
INSERT INTO autor VALUES ('cjulia@yahoo.es', 'Si');
INSERT INTO autor VALUES ('sergigil@ucm.es', 'si');


INSERT INTO asistente VALUES('juan@gmail.com', 'regular', nS.nextval, 2, 'no');
INSERT INTO asistente VALUES('antoniojimenez@yahoo.es', 'estudiante', 0, 2, 'no');
INSERT INTO asistente VALUES('abdul@gmail.com', 'regular', nS.nextval, 4, 'si');
INSERT INTO asistente VALUES('sergigil@ucm.es', 'estudiante', 0, 1, 'no');
INSERT INTO asistente VALUES('ana_g@hotmail.es', 'regular', nS.nextval, 5, 'no');
INSERT INTO asistente VALUES('aleksandra.89@gmail.com', 'regular', nS.nextval, 1, 'si');
INSERT INTO asistente VALUES('bernadetta@gmail.com', 'regular', nS.nextval, 2, 'no');
INSERT INTO asistente VALUES('hélène@gmail.com', 'regular', nS.nextval, 1, 'no');
INSERT INTO asistente VALUES('nuriag@msn.es', 'regular', nS.nextval, 2, 'no');
INSERT INTO asistente VALUES('arturo@gmail.com', 'regular', nS.nextval, 2, 'no');
INSERT INTO asistente VALUES('rodrigo@ucm.es', 'estudiante', 0, 8, 'no');
INSERT INTO asistente VALUES('cjulia@yahoo.es', 'regular', nS.nextval, 2, 'no');

INSERT INTO experto VALUES ('juan@gmail.com', 6);
INSERT INTO experto VALUES ('ana_g@hotmail.es', 3);
INSERT INTO experto VALUES ('nuriag@msn.es', 1);
INSERT INTO experto VALUES ('cjulia@yahoo.es', 12);
INSERT INTO experto VALUES ('aleksandra.89@gmail.com', 5);

INSERT INTO sesion VALUES (to_date('10/10/2010','dd/mm/yyyy'), 10, 'Seguridad', 'juan@gmail.com');
INSERT INTO sesion VALUES (to_date('10/10/2010','dd/mm/yyyy'), 1, 'Seguridad', NULL);
INSERT INTO sesion VALUES (to_date('07/11/2010','dd/mm/yyyy'), 5, 'Auditoria Forense', 'ana_g@hotmail.es');
INSERT INTO sesion VALUES (to_date('25/10/2010','dd/mm/yyyy'), 3, 'Sql', 'nuriag@msn.es');

INSERT INTO articulo VALUES(1, 'Security Manager', 'seguridad', 'no', to_date('10/10/2010','dd/mm/yyyy'),10);
INSERT INTO articulo VALUES(2, 'Realizar Auditorias', 'auditorias', 'no', to_date('07/11/2010','dd/mm/yyyy'), 5);
INSERT INTO articulo VALUES(5, 'Introduccion Sql', 'baseDatos', 'no', to_date('25/10/2010','dd/mm/yyyy'), 3);

INSERT INTO escribe VALUES('sergigil@ucm.es', 2);
INSERT INTO escribe VALUES('juan@gmail.com', 1);
INSERT INTO escribe VALUES('hélène@gmail.com', 5);
INSERT INTO escribe VALUES('cjulia@yahoo.es', 5);

INSERT INTO evalua VALUES ('ana_g@hotmail.es', 2, 2, 2);
INSERT INTO evalua VALUES ('juan@gmail.com', 1, 1, 1);
INSERT INTO evalua VALUES ('aleksandra.89@gmail.com', 5, 3, -1);
INSERT INTO evalua VALUES ('cjulia@yahoo.es', 2, 1, 3);
INSERT INTO evalua VALUES ('nuriag@msn.es', 2, -1, 1);
