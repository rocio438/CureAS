--creaamos la base de datos con el nombre en criterio al enunciado "generar una db con nombre "COMXXXXGYY" 
--donde XXXX hace referencia al numero de comision y YY hace referencia al nro del grupo
IF EXISTS(SELECT 1 FROM SYS.DATABASES WHERE NAME = 'COM5600G08')
	DROP DATABASE COM5600G08;
GO

CREATE DATABASE COM5600G08
GO

USE Com5600G08
GO

set nocount on
GO

--creacion de esquema para la creación de la db
IF EXISTS(SELECT 1 FROM SYS.schemas WHERE name LIKE 'dbHospital')
	DROP SCHEMA dbHospital;
GO
CREATE SCHEMA dbHospital;
GO
-- creación de esquema para los sp
IF EXISTS(SELECT 1 FROM SYS.schemas WHERE name LIKE 'spHospital')
	DROP SCHEMA spHospital;
GO
CREATE SCHEMA spHospital;
GO
--creacion de esquema para log
IF EXISTS(SELECT 1 FROM SYS.schemas WHERE name LIKE 'logHospital')
	DROP SCHEMA logHospital;
GO
CREATE SCHEMA logHospital;
GO

--**********CREACION DE TABLAS***********

--los nombres de las tablas son el singular --no es 'pacientes' es 'paciente'
  
-- sys.tables, proporciona información específica sobre todas las tablas de usuario en la base de datos actual.
-- SYS.all_objects,contiene información sobre todos los objetos en la base de datos : vistas, sp, tablas, funciones, trigges
--dependiendo de la necesita de información que requerimos, una vista puede ser mas útil que la otra, en este caso, sería más óptimo utilizar sys.tables, en contexto de performance.

--- tabla paciente
IF EXISTS(SELECT 1 FROM SYS.all_objects WHERE type = 'U' AND object_id = OBJECT_ID('[dbHospital].[paciente]')) --type = 'U' filtra las tablas de usuario
	DROP TABLE dbHospital.paciente;
GO
-- otra forma de consultar si existe la tabla 
/*
	IF EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'paciente' AND schema_id = SCHEMA_ID('dbHospital')) 
		DROP TABLE dbHospital.paciente;
	GO
*/

CREATE TABLE dbHospital.paciente(

	id_historia_clinica		int  identity(1,1) PRIMARY KEY, -- ponemos identity?-charlarlo con el grupo-
	nombre				    	varchar(30) NOT NULL,
	apellido				    varchar(30) NOT NULL,
	apellidoMaterno			varchar(30) NOT NULL,
	fechaNacimiento			datetime NOT NULL, -- consultar con el grupo
	tipoDoc					    varchar(10) NOT NULL,
	numDoc					    char(8) NOT NULL,
	sexoBio					    char NOT NULL,
	genero					    varchar(20) NOT NULL,
	nacionalidad			  varchar (20) NOT NULL,
	fotoPerfil				  varchar (50) NOT NULL,
	mail					      varchar(50) UNIQUE NOT NULL,
	telFijo				      varchar(14) NOT NULL,
	telAlt					    varchar(14),
	telLaboral				  varchar(14),
	fechaRegistro			  date NOT NULL,
	fechaAct				    date NOT NULL,
	usuarioAct				  varchar(40), -- NOT NULL ? 
	CONSTRAINT CK_mail CHECK (
		mail LIKE '%@%'							-- Debe contener al menos un símbolo "@".
		AND mail LIKE '%.%'					-- Debe contener al menos un punto ".".
		AND mail NOT LIKE '%@%@%'		-- Debe tener solo un símbolo "@".
		AND LEN(mail) > 5						-- Debe tener al menos 5 caracteres.
		AND LEN(mail) < 30					-- Debe tener hasta 30 caracteres.
	),
	CONSTRAINT CK_telFijo CHECK(
	    LEN(telFijo) >= 10						    -- Debe tener al menos 10 caracteres.
	    AND LEN(telFijo) <= 13					  -- Debe tener como máximo 13 caracteres.
		--AND ISNUMERIC(telFijo) = 1			  -- Debe ser numérico.
		AND telFijo NOT LIKE '%[^(0-9)\-]%'	-- Debe contener solo dígitos numéricos.
	),
	CONSTRAINT CK_telAlt CHECK((
	    LEN(telAlt) >= 10						    -- Debe tener al menos 10 caracteres.
	    AND LEN(telAlt) <= 14					  -- Debe tener como máximo 13 caracteres.
		--AND ISNUMERIC(telAlt) = 1				 -- Debe ser numérico.
		AND telAlt NOT LIKE '%[^(0-9)\-]%')	-- Debe contener solo dígitos numéricos.
		--OR telAlt IS NULL						    --Puede ser NULL-> no es extrictamente necesario, ya se especifíco al momento de crear el campo	
	),
	CONSTRAINT CK_telLaboral CHECK((
	    LEN(telLaboral) >= 10					      -- Debe tener al menos 10 caracteres.
	    AND LEN(telLaboral) <= 13				    -- Debe tener como máximo 13 caracteres.
		--AND ISNUMERIC(telLaboral) = 1			  -- Debe ser numérico.
		AND telLaboral NOT LIKE '%[^(0-9)\-]%')	-- Debe contener solo dígitos numéricos.
		--OR telLaboral IS NULL					  -- Puede ser NULL ->no es extrictamente necesario, ya se especifíco al momento de crear el campo					
	),
	CONSTRAINT CK_sexoBio CHECK(
		sexoBio IN ('F','M')					-- Debe ser 'Femenino' o 'Masculino'
	),
	CONSTRAINT CK_nroDoc CHECK (
		numDoc NOT LIKE '[^0-9]'			-- Debe ser unicamente dígitos. " [^0-9] " -> 'no puede ser distinto a numerico' 
		AND LEN(numDoc) >= 7					-- Debe tener una longitud mayor o igual a 7 dígitos.
	)
);
GO -- NO OLVIDARSE EL GO

--******************************************************************************************

--tabla estudio
IF EXISTS(SELECT 1 FROM SYS.all_objects WHERE type = 'U' AND object_id = OBJECT_ID('[dbHospital].[estudio]')) --type = 'U' filtra las tablas de usuario
	DROP TABLE dbHospital.estudio;
GO
-- otra forma de consultar si existe la tabla 
/*
	IF EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'estudio' AND schema_id = SCHEMA_ID('dbHospital')) 
		DROP TABLE dbHospital.estudio;
	GO
*/

CREATE TABLE dbHospital.estudio(
	id_estudio			int PRIMARY KEY,
	fecha				    datetime NOT NULL,
	nombreEstudio		varchar(80) NOT NULL,
	autorizado			BIT DEFAULT 0, -- tipo de dato BIT- > dato bool,0 =false, 1= true , el contexto -> 0= no autorizado, 1= autorizado 
	docResultado		varchar(100) NOT NULL,
	imagenResultado	varchar(100) NOT NULL,
	id_hist_clinica	int,
	CONSTRAINT fk_estudioPaciente FOREIGN KEY (id_hist_clinica) REFERENCES dbHospital.paciente(id_historia_clinica)
);
GO

--******************************************************************************************

--tabla usuario

-- FUNCION de tipo ESCALAR -> nos confirma si existe el dni en insertado en la tabla usuario, ya que el mismo debe coincidir, el usuario debe ser un paciente registrado

IF EXISTS(SELECT 1 FROM SYS.all_objects WHERE type = 'FN' AND object_id = OBJECT_ID('[spHospital].[verificacionDocPaciente]'))
	DROP FUNCTION spHospital.verificacionDocPaciente;
GO

CREATE OR ALTER FUNCTION spHospital.verificacionDocPaciente(@dni CHAR(8))
RETURNS BIT --retorna un tipo bool, 1 = true, 0= false
AS
BEGIN
	DECLARE @dniPaciente CHAR(10) = 'datorand'; -- inicializamos la variable dniPaciente con una cadena, primero para que no tome datos basura, 
											                      	--segundo, para que sepamos con certeza que si no existe el documento en la tabla paciente, la comparación efectivamente va a ser falsa

	SELECT @dniPaciente = numDoc FROM dbHospital.paciente WHERE numDoc = @dni --declaramos variable y le asignamos el resultado de la consulta
	
	IF(@dniPaciente <> @dni) --si son distintos, signfinica que dicho documento no existe en la tabla paciente, es un paciente no existente 
		RETURN 0

	RETURN 1
END
GO

IF EXISTS(SELECT 1 FROM SYS.all_objects WHERE type = 'U' AND object_id = OBJECT_ID('[dbHospital].[usuario]')) --type = 'U' filtra las tablas de usuario
	DROP TABLE dbHospital.usuario;
GO
-- otra forma de consultar si existe la tabla 
/*
	IF EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'usuario' AND schema_id = SCHEMA_ID('dbHospital')) 
		DROP TABLE dbHospital.usuario;
	GO
*/

-- usuario es DEBIL de PACIENTE, ya que no existiria un usuario sin la existencia de un paciente.
CREATE TABLE dbHospital.usuario(
	id_usuario_paciente		int,
	id_doc_paciente			  char(8), --> DNI , debe coincidir con el documento, para eso la funcion de arriba
	contrasenia				    varchar(40) NOT NULL,
	fechaCreacion			    date NOT NULL,
	
	CONSTRAINT pk_usuario PRIMARY KEY (id_usuario_paciente,id_doc_paciente),
	CONSTRAINT fk_usuarioPaciente FOREIGN KEY (id_usuario_paciente) REFERENCES dbHospital.paciente(id_historia_clinica),

	CONSTRAINT ck_contraseniaUsu CHECK (
		LEN(contrasenia) >= 8								                -- Longitud mínima de 8 caracteres
		AND CHARINDEX(UPPER(contrasenia), contrasenia) > 0	-- Al menos una letra mayúscula
		AND CHARINDEX(LOWER(contrasenia), contrasenia) > 0	-- Al menos una letra minúscula
		AND PATINDEX('%[0-9]%', contrasenia) > 0		      	-- Al menos un número
	),
	CONSTRAINT ck_idPaciente CHECK (
		id_doc_paciente NOT LIKE '[^0-9]'                            --es necesario este check, existiendo la funcion?, con solo llamar a la funcion bastaría?
		AND LEN(id_doc_paciente) >= 7
		AND spHospital.verificacionDocPaciente(id_doc_paciente) = 1 --aca llamamos a la funcion para verificar que exista y coincidencia del DNI de la tabla PACIENTE, entonces se valida la cuenta usuario
	)
);
GO

--******************************************************************************************

--tabla domicilio
IF EXISTS(SELECT 1 FROM SYS.all_objects WHERE type = 'U' AND object_id = OBJECT_ID('[dbHospital].[domicilio]')) --type = 'U' filtra las tablas de usuario
	DROP TABLE dbHospital.domicilio;
GO
-- otra forma de consultar si existe la tabla 
/*
	IF EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'domicilio' AND schema_id = SCHEMA_ID('dbHospital')) 
		DROP TABLE dbHospital.domicilio;
	GO
*/

CREATE TABLE dbHospital.domicilio(
	id_domicilio		int IDENTITY (1,1) PRIMARY KEY ,--y si ponemos identity
	calle				    varchar(30) NOT NULL,
	numero				  int NOT NULL,
	piso				    int,
	departamento		int,
	codigoPostal		int NOT NULL,
	pais				    varchar(20) NOT NULL,
	provincia			  varchar(30) NOT NULL,
	localidad			  varchar(30)  NOT NULL,
	id_hist_clinica	int,
	CONSTRAINT fk_domicilioPaciente FOREIGN KEY (id_hist_clinica) REFERENCES dbHospital.paciente(id_historia_clinica),
	CONSTRAINT ck_cpDomicilio CHECK (LEN(codigoPostal) = 4 )
);
GO

--******************************************************************************************

--tabla cobertura
IF EXISTS(SELECT 1 FROM SYS.all_objects WHERE type = 'U' AND object_id = OBJECT_ID('[dbHospital].[cobertura]')) --type = 'U' filtra las tablas de usuario
	DROP TABLE dbHospital.cobertura;
GO
-- otra forma de consultar si existe la tabla 
/*
	IF EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'cobertura' AND schema_id = SCHEMA_ID('dbHospital')) 
		DROP TABLE dbHospital.cobertura;
	GO
*/

CREATE TABLE dbHospital.cobertura(
	id_cobertura		  int PRIMARY KEY, -- vamo a poner un codigo de 7 digitos, asi sacamos el identity un poco
	imagenCredencial	varchar(80) NOT NULL, -- como planteamos la imagen? es un link?
	nroSocio			    int NOT NULL,
	fechaRegistro		  date NOT NULL, --es necesario?
	id_hist_clinica		int,
	CONSTRAINT fk_coberturaPaciente FOREIGN KEY (id_hist_clinica) REFERENCES dbHospital.paciente(id_historia_clinica),
	CONSTRAINT ck_idCobertura CHECK ( LEN (id_cobertura) = 7) --podemos sacarlo tranqui
);
GO
--******************************************************************************************

--tabla prestador

IF EXISTS(SELECT 1 FROM SYS.all_objects WHERE type = 'U' AND object_id = OBJECT_ID('[dbHospital].[prestador]')) --type = 'U' filtra las tablas de usuario
	DROP TABLE dbHospital.prestador;
GO
-- otra forma de consultar si existe la tabla 
/*
	IF EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'prestador' AND schema_id = SCHEMA_ID('dbHospital')) 
		DROP TABLE dbHospital.prestador;
	GO
*/

CREATE TABLE dbHospital.prestador (
	id_prestado			int PRIMARY KEY,
	nombrePrestador		varchar(50) UNIQUE NOT NULL,
	planPrestador		varchar(50) NOT NULL,
	activo				bit default 1,
	id_cobertura		int,
	CONSTRAINT fk_prestadorCobertura FOREIGN KEY (id_cobertura) REFERENCES dbHospital.cobertura (id_cobertura)
);
GO

--******************************************************************************************

--tabla estado de turno
IF EXISTS(SELECT 1 FROM SYS.all_objects WHERE type = 'U' AND object_id = OBJECT_ID('[dbHospital].[estadoTurno]')) --type = 'U' filtra las tablas de usuario
	DROP TABLE dbHospital.estadoTurno;
GO
-- otra forma de consultar si existe la tabla 
/*
	IF EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'estadoTurno' AND schema_id = SCHEMA_ID('dbHospital')) 
		DROP TABLE dbHospital.estadoTurno;
	GO
*/

CREATE TABLE dbHospital.estadoTurno(
	id_estado_turno		int PRIMARY KEY,
	estado	          varchar(20) NOT NULL,

	CONSTRAINT CK_estadoTurno CHECK(
		UPPER(estado) = 'ATENDIDO'
		OR UPPER(estado) = 'AUSENTE'
		OR UPPER(estado) = 'CANCELADO'
	)
);
GO

--******************************************************************************************

--tabla tipo de turno
IF EXISTS(SELECT 1 FROM SYS.all_objects WHERE type = 'U' AND object_id = OBJECT_ID('[dbHospital].[tipoTurno]')) --type = 'U' filtra las tablas de usuario
	DROP TABLE dbHospital.tipoTurno;
GO
-- otra forma de consultar si existe la tabla 
/*
	IF EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'tipoTurno' AND schema_id = SCHEMA_ID('dbHospital')) 
		DROP TABLE dbHospital.tipoTurno;
	GO
*/

CREATE TABLE dbHospital.tipoTurno(--no se si las campos estan bien
	id_tipo_turno		int PRIMARY KEY,
	tipoTurno		varchar(10) NOT NULL,

	CONSTRAINT CK_tipoTurno CHECK(
		UPPER(tipoTurno) = 'PRESENCIAL'
		OR UPPER(tipoTurno) = 'VIRTUAL'
	)
);
go

--*******************************************************************************************

-- tabla sede de atencion
IF EXISTS(SELECT 1 FROM SYS.all_objects WHERE type = 'U' AND object_id = OBJECT_ID('[dbHospital].[sedeDeAtencion]')) --type = 'U' filtra las tablas de usuario
	DROP TABLE dbHospital.sedeDeAtencion;
GO
-- otra forma de consultar si existe la tabla 
/*
	IF EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'sedeDeAtencion' AND schema_id = SCHEMA_ID('dbHospital')) 
		DROP TABLE dbHospital.sedeDeAtencion;
	GO
*/

CREATE TABLE dbHospital.sedeDeAtencion(
	id_sede			   int PRIMARY KEY,
	nombreDeSede	 varchar(30) NOT NULL,
	direccionSede	 varchar(50) NOT NULL
);
go

--******************************************************************************************

-- tabla especialidad

IF EXISTS(SELECT 1 FROM SYS.all_objects WHERE type = 'U' AND object_id = OBJECT_ID('[dbHospital].[especialidad]')) --type = 'U' filtra las tablas de usuario
	DROP TABLE dbHospital.especialidad;
GO
-- otra forma de consultar si existe la tabla 
/*
	IF EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'especialidad'   AND schema_id = SCHEMA_ID('dbHospital')) 
		DROP TABLE dbHospital.especialidad;
	GO
*/

CREATE TABLE dbHospital.especialidad(
	id_especialidad			  int PRIMARY KEY, 
	nombreEspecialidad		varchar(40),

	CONSTRAINT ck_idEspecialidad CHECK ( LEN(id_especialidad) = 5) --decidimos que, el id debe tener 5 digitos (esto podemos borrarlo)
);
GO

--******************************************************************************************

-- tabla medico

IF EXISTS(SELECT 1 FROM SYS.all_objects WHERE type = 'U' AND object_id = OBJECT_ID('[dbHospital].[medico]')) --type = 'U' filtra las tablas de usuario
	DROP TABLE dbHospital.medico;
GO
-- otra forma de consultar si existe la tabla 
/*
	IF EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'medico'   AND schema_id = SCHEMA_ID('dbHospital')) 
		DROP TABLE dbHospital.medico;
	GO
*/

CREATE TABLE dbHospital.medico(
	id_medico				 int PRIMARY KEY,-- 
	nombre					 varchar(30) NOT NULL,
	apellido				 varchar(30) NOT NULL,
	nroMatricula			 int NOT NULL,
	id_especialidad_medico	 int,
	CONSTRAINT fk_medicoEspecialidad FOREIGN KEY (id_especialidad_medico) REFERENCES dbHospital.especialidad (id_especialidad),
	CONSTRAINT ck_idMedico CHECK (LEN(id_medico) = 3) --podemos borrarlo y usar identity
);
GO

--******************************************************************************************

--tabla dias x sede
IF EXISTS(SELECT 1 FROM SYS.all_objects WHERE type = 'U' AND object_id = OBJECT_ID('[dbHospital].[diasXsede]')) --type = 'U' filtra las tablas de usuario
	DROP TABLE dbHospital.diasXsede;
GO
-- otra forma de consultar si existe la tabla 
/*
	IF EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'diasXsede'   AND schema_id = SCHEMA_ID('dbHospital')) 
		DROP TABLE dbHospital.diasXsede;
	GO
*/

CREATE TABLE dbHospital.diasXsede(
	id_dia_sede			int IDENTITY (1,1) PRIMARY KEY,--podemos utilizar otro criterio para este id, puede ser != de identity
	dia				      varchar(10) NOT NULL, 
	horaInicio		  varchar(10) NOT NULL, 
	id_medico	      int,
	id_sede_atencion int,
	CONSTRAINT fk_diasXsedeMedico FOREIGN KEY (id_medico) REFERENCES dbHospital.medico (id_medico),
	CONSTRAINT fk_diasXsedeSedeAtencion FOREIGN KEY (id_sede_atencion) REFERENCES dbHospital.sedeDeAtencion (id_sede),
	CONSTRAINT UQ_diasSede UNIQUE (id_dia_sede, id_medico, dia, horaInicio) -- para un mismo dia, misma sede, mismo medico y misma hora solo existe 1 turno, por ende debe ser unico
);
GO

--******************************************************************************************

--tabla reserva de turno medico
IF EXISTS(SELECT 1 FROM SYS.all_objects WHERE type = 'U' AND object_id = OBJECT_ID('[dbHospital].[reservaTurnoMedico]')) --type = 'U' filtra las tablas de usuario
	DROP TABLE dbHospital.reservaTurnoMedico;
GO
-- otra forma de consultar si existe la tabla 
/*
	IF EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'reservaTurnoMedico' AND schema_id = SCHEMA_ID('dbHospital')) 
		DROP TABLE dbHospital.reservaTurnoMedico;
	GO
*/

CREATE TABLE dbHospital.reservaTurnoMedico(
	id_reserva_turno	int identity(1,1) PRIMARY KEY,
	fecha				      date NOT NULL,
	hora				      time NOT NULL,
	id_diaSede		  	int,
	id_paciente			  int,
	id_estado			    int,
	id_tipoTurno		  int,
	id_medico			    int,
	id_especialidad		int,
	id_sedeAten			  int,
	
	CONSTRAINT FK_reservaDiasxSede FOREIGN KEY (id_diaSede) REFERENCES dbHospital.diasXsede (id_dia_sede),
	CONSTRAINT FK_reservaPaciente FOREIGN KEY (id_paciente) REFERENCES dbHospital.paciente (id_historia_clinica),
	CONSTRAINT FK_reservaEstadoTurno FOREIGN KEY (id_estado) REFERENCES dbHospital.estadoTurno (id_estado_turno),
	CONSTRAINT FK_reservaTipoTurno FOREIGN KEY (id_tipoTurno) REFERENCES dbHospital.tipoTurno(id_tipo_turno),
	CONSTRAINT FK_reservaMedico FOREIGN KEY (id_medico) REFERENCES dbHospital.medico (id_medico),
	CONSTRAINT FK_reservaEspecialidadMed FOREIGN KEY (id_especialidad) REFERENCES dbHospital.especialidad (id_especialidad),
	CONSTRAINT FK_reservaSede FOREIGN KEY (id_sedeAten) REFERENCES dbHospital.sedeDeAtencion (id_sede)
);
GO

--***********************************************************************************************************



-- ******CREACIÓN DE STORE PROCEDURE DE INSERCIÓN***************
