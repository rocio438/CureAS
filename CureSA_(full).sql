/*
---------------- !IMPORTANTE! ------------------
Antes de ejecutar este script cambiar la siguiente variable '@RUTA'
del archivo para realizar la carga de datos masiva, indique el path 
correcto con sus archivos de carga.

	@rutasede 		
	@rutamedico 	
	@rutaprestador 	
	@rutapaciente 	
	@rutaautorizacion

*/
USE master;
-- Creación de la base de datos y sus esquemas
-- ===========================================
IF EXISTS(SELECT 1 FROM SYS.DATABASES WHERE NAME = 'CureSA')
	DROP DATABASE CureSA;
GO

CREATE DATABASE CureSA
GO

ALTER DATABASE CureSA
	SET COMPATIBILITY_LEVEL = 140

USE CureSA
GO



IF EXISTS(SELECT 1 FROM SYS.schemas WHERE name LIKE 'dbCureSA')
	DROP SCHEMA dbCureSA;
GO

CREATE SCHEMA dbCureSA;
GO

IF EXISTS(SELECT 1 FROM SYS.schemas WHERE name LIKE 'spCureSA')
	DROP SCHEMA spCureSA;
GO

CREATE SCHEMA spCureSA
GO

IF EXISTS(SELECT 1 FROM SYS.schemas WHERE name LIKE 'logCureSA')
	DROP SCHEMA logCureSA;
GO

CREATE SCHEMA logCureSA
GO


-- Creación de las tablas especificadas en el DER
-- ==============================================

IF EXISTS(SELECT 1 FROM SYS.all_objects
	WHERE type = 'U' AND object_id = OBJECT_ID('[dbCureSA].[Prestador]'))
	DROP TABLE dbCureSA.Prestador;
GO

CREATE TABLE dbCureSA.Prestador(
	id				INT IDENTITY(1,1),
	nombre			VARCHAR(50) NOT NULL,
	[plan]			VARCHAR(50) NOT NULL,
	activo			BIT DEFAULT 1,
	
	CONSTRAINT PK_idPrestador PRIMARY KEY (id),
	CONSTRAINT UQ_nombrePrestador UNIQUE (nombre)
)
GO

IF EXISTS(SELECT 1 FROM SYS.all_objects
	WHERE type = 'U' AND object_id = OBJECT_ID('[dbCureSA].[Cobertura]'))
	DROP TABLE dbCureSA.Cobertura;
GO

CREATE TABLE dbCureSa.Cobertura(
	id					INT IDENTITY(1,1),
	idPrestador			INT NOT NULL,
	nroSocio			INT NOT NULL,
	fechaRegistro		DATE NOT NULL,
	imgCredencial		VARBINARY(MAX),
	
	CONSTRAINT PK_idCobertura PRIMARY KEY (id),
	CONSTRAINT FK_idPrestadorCobertura FOREIGN KEY (idPrestador) REFERENCES dbCureSA.Prestador (id),
	CONSTRAINT UQ_nroSocioCobertura UNIQUE (nroSocio)
)
GO

IF EXISTS(SELECT 1 FROM SYS.all_objects WHERE type = 'U' AND object_id = OBJECT_ID('[dbCureSA].[Paciente]'))
	DROP TABLE dbCureSA.Paciente;
GO

CREATE TABLE dbCureSA.Paciente(
	idHistoriaClinica	INT IDENTITY(1,1),
	nombre				VARCHAR(50) NOT NULL,
	apellido			VARCHAR(50) NOT NULL,
	apellidoMaterno		VARCHAR(50),
	fecNac				DATE NOT NULL,
	tipoDoc				CHAR(3) NOT NULL,
	nroDoc				CHAR(8) NOT NULL,
	sexo				CHAR NOT NULL,
	genero				CHAR(10) NOT NULL,
	nacionalidad		VARCHAR(25) NOT NULL,
	FK_idCobertura		INT NOT NULL,
	fotoPerfil			VARBINARY(MAX),
	mail				VARCHAR(50),
	telFijo				CHAR(14) NOT NULL,
	telAlt				CHAR(14),
	telLaboral			CHAR(14),
	fechaReg			DATETIME NOT NULL,
	fechaAct			DATETIME,
	usuAct				VARCHAR(50),
	activo				BIT DEFAULT 1,
	
	CONSTRAINT PK_idHistoriaPac PRIMARY KEY (idHistoriaClinica),
	CONSTRAINT FK_idCoberturaPac FOREIGN KEY (FK_idCobertura) REFERENCES dbCureSA.Cobertura (id),
	
	CONSTRAINT UQ_tipoDoc_docPac UNIQUE (tipoDoc,nroDoc),
	
	CONSTRAINT CK_mailPac CHECK (
		mail LIKE '%@%'							-- Debe contener al menos un símbolo "@".
		AND mail LIKE '%.%'						-- Debe contener al menos un punto ".".
		AND mail NOT LIKE '%@%@%'				-- Debe tener solo un símbolo "@".
		AND LEN(mail) >= 5						-- Debe tener al menos 5 caracteres.
	),
	CONSTRAINT CK_telFijo CHECK(
	    LEN(telFijo) >= 10						-- Debe tener al menos 10 caracteres.
	    AND LEN(telFijo) <= 13					-- Debe tener como máximo 13 caracteres.
		--AND ISNUMERIC(telFijo) = 1			-- Debe ser numérico.
		AND telFijo NOT LIKE '%[^(0-9)\-]%'		-- Debe contener solo dígitos numéricos.
	),
	CONSTRAINT CK_telAlt CHECK((
	    LEN(telAlt) >= 10						-- Debe tener al menos 10 caracteres.
	    AND LEN(telAlt) <= 14					-- Debe tener como máximo 13 caracteres.
		--AND ISNUMERIC(telAlt) = 1				-- Debe ser numérico.
		AND telAlt NOT LIKE '%[^(0-9)\-]%')		-- Debe contener solo dígitos numéricos.
		OR telAlt IS NULL
	),
	CONSTRAINT CK_telLaboral CHECK((
	    LEN(telLaboral) >= 10					-- Debe tener al menos 10 caracteres.
	    AND LEN(telLaboral) <= 13				-- Debe tener como máximo 13 caracteres.
		--AND ISNUMERIC(telLaboral) = 1			-- Debe ser numérico.
		AND telLaboral NOT LIKE '%[^(0-9)\-]%')	-- Debe contener solo dígitos numéricos.
		OR telLaboral IS NULL
	),
	CONSTRAINT CK_sexo CHECK(
		sexo IN ('F','M')						-- Debe ser 'Femenino' o 'Masculino'
	),
	CONSTRAINT CK_nroDoc CHECK (
		nroDoc NOT LIKE '[^0-9]'				-- Debe ser unicamente dígitos.
		AND LEN(nroDoc) > 7						-- Debe ser mayor a 7 dígitos.
	),
)
GO

IF EXISTS(SELECT 1 FROM SYS.all_objects WHERE type = 'U' AND object_id = OBJECT_ID('[dbCureSA].[Domicilio]'))
	DROP TABLE dbCureSA.Domicilio;
GO

CREATE TABLE dbCureSA.Domicilio(
	id					INT IDENTITY(1,1),
	idPaciente			INT,
	calle				VARCHAR(50) NOT NULL,
	numero				INT NOT NULL,
	piso				INT,
	departamento		INT,
	cp					INT NOT NULL,
	pais				VARCHAR(50) NOT NULL DEFAULT 'Argentina',
	provincia			VARCHAR(50) NOT NULL DEFAULT 'Buenos Aires',
	localidad			VARCHAR(50) NOT NULL,
	
	CONSTRAINT PK_idDomicilio PRIMARY KEY (id,idPaciente),
	CONSTRAINT FK_idPaciente FOREIGN KEY(idPaciente) REFERENCES dbCureSA.Paciente(idHistoriaClinica),
	CONSTRAINT CK_cpDomicilio CHECK (
		cp >= 1000 
		AND cp <= 9999	--El código postal de 4 digitos.
	)
)
GO

IF EXISTS(SELECT 1 FROM SYS.all_objects WHERE type = 'FN' AND object_id = OBJECT_ID('[spCureSA].[determinarPaciente]'))
	DROP FUNCTION spCureSA.Domicilio;
GO
				
CREATE OR ALTER FUNCTION spCureSA.determinarPaciente(@dni CHAR(10))
RETURNS BIT
AS
BEGIN
	DECLARE @dniPaciente as CHAR(10) = 'aaaaaaaa';

	SELECT @dniPaciente = nroDoc FROM dbCureSA.Paciente
	WHERE nroDoc = @dni

	IF(@dniPaciente <> @dni)
		RETURN 0

	RETURN 1
END
GO

IF EXISTS(SELECT 1 FROM SYS.all_objects WHERE type = 'U' AND object_id = OBJECT_ID('[dbCureSA].[Usuario]'))
	DROP TABLE dbCureSA.Usuario;
GO

CREATE TABLE dbCureSA.Usuario(
	idUsuario			INT,
	idPaciente			CHAR(10),						-- El Usuario debe coincidir con el documento
	contrasenia			VARCHAR(50) NOT NULL,
	fechaCreacion		DATE NOT NULL,
	
	CONSTRAINT PK_idUsuario PRIMARY KEY (idUsuario,idPaciente),
	CONSTRAINT FK_idUsuario FOREIGN KEY (idUsuario) REFERENCES dbCureSA.Paciente(idHistoriaClinica),
	
	CONSTRAINT CK_contraseniaUsu CHECK (
		LEN(contrasenia) >= 8								-- Longitud mínima de 8 caracteres
		AND CHARINDEX(UPPER(contrasenia), contrasenia) > 0	-- Al menos una letra mayúscula
		AND CHARINDEX(LOWER(contrasenia), contrasenia) > 0	-- Al menos una letra minúscula
		AND PATINDEX('%[0-9]%', contrasenia) > 0			-- Al menos un número
	),
	CONSTRAINT CK_idPaciente CHECK (
		idPaciente NOT LIKE '[^0-9]'
		AND LEN(idPaciente) > 7
		AND spCureSA.determinarPaciente(idPaciente) = 1
	)
)
GO

IF EXISTS(SELECT 1 FROM SYS.all_objects WHERE type = 'U' AND object_id = OBJECT_ID('[dbCureSA].[Estudio]'))
	DROP TABLE dbCureSA.Estudio;
GO

CREATE TABLE dbCureSA.Estudio(
	idEstudio			INT IDENTITY(1,1),
	idPaciente			INT,
	fecha				DATETIME NOT NULL,
	nombreEstudio		VARCHAR(50) NOT NULL,
	autorizado			BIT DEFAULT 0,				--0 = No autorizado; 1 = Autorizado
	docResult			VARBINARY(MAX),
	imgResult			VARBINARY(MAX),
	
	CONSTRAINT PK_idEstudioEs PRIMARY KEY (idEstudio),
	CONSTRAINT FK_idPacienteEs FOREIGN KEY (idPaciente) REFERENCES dbCureSA.Paciente (idHistoriaClinica),
)
GO

IF EXISTS(SELECT 1 FROM SYS.all_objects WHERE type = 'U' AND object_id = OBJECT_ID('[dbCureSA].[Especialidad]'))
	DROP TABLE dbCureSA.Especialidad;
GO

CREATE TABLE dbCureSA.Especialidad(
	id		INT IDENTITY(1,1),
	nombre	VARCHAR(50) NOT NULL,
	
	CONSTRAINT PK_idEspecialidad PRIMARY KEY (id)
)
GO

IF EXISTS(SELECT 1 FROM SYS.all_objects WHERE type = 'U' AND object_id = OBJECT_ID('[dbCureSA].[Medico]'))
	DROP TABLE dbCureSA.Medico;
GO

CREATE TABLE dbCureSA.Medico(
	id					INT IDENTITY(1,1),
	idEspecialidad		INT NOT NULL,
	nombre				VARCHAR(50) NOT NULL,
	apellido			VARCHAR(50) NOT NULL,
	nroMatricula		VARCHAR(50) NOT NULL,
	activo				BIT DEFAULT 1,
	
	CONSTRAINT PK_idMedico PRIMARY KEY (id),
	CONSTRAINT FK_idEspecialidadMedico FOREIGN KEY (idEspecialidad) REFERENCES dbCureSA.Especialidad (id)
)
GO

IF EXISTS(SELECT 1 FROM SYS.all_objects WHERE type = 'U' AND object_id = OBJECT_ID('[dbCureSA].[Sede]'))
	DROP TABLE dbCureSA.Sede;
GO

CREATE TABLE dbCureSA.Sede(
	id			INT IDENTITY(1,1),
	nombre		VARCHAR(50) NOT NULL,
	direccion	VARCHAR(50) NOT NULL,
	
	CONSTRAINT PK_idSede PRIMARY KEY (id)
)
GO

IF EXISTS(SELECT 1 FROM SYS.all_objects WHERE type = 'U' AND object_id = OBJECT_ID('[dbCureSA].[DiasXSede]'))
	DROP TABLE dbCureSA.DiasXSede;
GO

CREATE TABLE dbCureSA.DiasXSede(
	id			INT IDENTITY(1,1),
	idSede		INT,
	idMedico	INT,
	dia			DATE NOT NULL,
	horaInicio	TIME NOT NULL,

	CONSTRAINT PK_idDiasXSede PRIMARY KEY (id),
	CONSTRAINT FK_idSedeDias FOREIGN KEY (idSede) REFERENCES dbCureSA.Sede (id),
	CONSTRAINT FK_idMedicoDias FOREIGN KEY (idMedico) REFERENCES dbCureSA.Medico (id),
	CONSTRAINT UQ_DiasSede UNIQUE (idSede, idMedico, dia, horaInicio)
)
GO

IF EXISTS(SELECT 1 FROM SYS.all_objects WHERE type = 'U' AND object_id = OBJECT_ID('[dbCureSA].[TipoTurno]'))
	DROP TABLE dbCureSA.TipoTurno;
GO

CREATE TABLE dbCureSA.TipoTurno(
	id		INT IDENTITY(1,1),
	tipo	VARCHAR(25) NOT NULL,
	
	CONSTRAINT PK_idTipoTurno PRIMARY KEY (id),
	CONSTRAINT CK_tipoTurno CHECK(
		UPPER(tipo) = 'PRESENCIAL'
		OR UPPER(tipo) = 'VIRTUAL'
	)
)
GO

IF EXISTS(SELECT 1 FROM SYS.all_objects WHERE type = 'U' AND object_id = OBJECT_ID('[dbCureSA].[EstadoTurno]'))
	DROP TABLE dbCureSA.EstadoTurno;
GO

CREATE TABLE dbCureSA.EstadoTurno(
	id		INT IDENTITY(1,1),
	estado	VARCHAR(12) NOT NULL,
	
	CONSTRAINT PK_idEstadoTurno PRIMARY KEY(id),
	CONSTRAINT CK_estadoTurno CHECK(
		UPPER(estado) = 'ATENDIDO'
		OR UPPER(estado) = 'AUSENTE'
		OR UPPER(estado) = 'CANCELADO'
	)
)
GO

IF EXISTS(SELECT 1 FROM SYS.all_objects WHERE type = 'U' AND object_id = OBJECT_ID('[dbCureSA].[ReservaTurno]'))
	DROP TABLE dbCureSA.ReservaTurno;
GO

CREATE TABLE dbCureSA.ReservaTurno(
	id				INT IDENTITY(1,1),
	fecha			DATE NOT NULL,
	hora			TIME NOT NULL,
	idDiaSede		INT,
	idPaciente		INT,
	idEstado		INT,
	idTipo			INT,
	idMedico		INT,
	idEspecialidad	INT,
	idSede			INT,
	
	CONSTRAINT PK_idReservaTurno PRIMARY KEY (id),
	CONSTRAINT FK_idDiaSedeTurno FOREIGN KEY (idDiaSede) REFERENCES dbCureSA.DiasXSede (id),
	CONSTRAINT FK_idPacienteTurno FOREIGN KEY (idPaciente) REFERENCES dbCureSA.Paciente (idHistoriaClinica),
	CONSTRAINT FK_idEstadoTurno FOREIGN KEY (idEstado) REFERENCES dbCureSA.EstadoTurno (id),
	CONSTRAINT FK_idTipoTurno FOREIGN KEY (idTipo) REFERENCES dbCureSA.TipoTurno(id),
	CONSTRAINT FK_idMedicoTurno FOREIGN KEY (idMedico) REFERENCES dbCureSA.Medico (id),
	CONSTRAINT FK_idEspecialidadTurno FOREIGN KEY (idEspecialidad) REFERENCES dbCureSA.Especialidad (id),
	CONSTRAINT FK_idSedeTurno FOREIGN KEY (idSede) REFERENCES dbCureSA.Sede (id)
)
GO

IF EXISTS(SELECT 1 FROM SYS.all_objects WHERE type = 'U' AND object_id = OBJECT_ID('[logCureSA].[Registro]'))
	DROP TABLE logCureSA.Registro;
GO

CREATE TABLE logCureSA.Registro(
	id		INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
	fecha	DATE DEFAULT GETDATE(),
	hora	TIME DEFAULT GETDATE(),
	texto	VARCHAR(250),
	modulo	VARCHAR(10)
)
GO

IF EXISTS(SELECT 1 FROM SYS.all_objects WHERE type = 'U' AND object_id = OBJECT_ID('[dbCureSa].[Autorizacion]'))
	DROP TABLE dbCureSa.Autorizacion;
GO

CREATE TABLE dbCureSa.Autorizacion (
	idAutorizacion	INT IDENTITY(1,1),
	idPrestador		INT,				-- FK -> tabla prestadores
	area			VARCHAR(50),
	nombreEstudio	VARCHAR(100),
	porcCobertura	DECIMAL(5,4),
	costo			DECIMAL(8,2),
	autorizacion	BIT,

	CONSTRAINT "PK_idAutorizacion_Autorizacion" PRIMARY KEY (idAutorizacion),
	CONSTRAINT "FK_idPrestador_Prestador" FOREIGN KEY (idPrestador) REFERENCES dbCureSa.Prestador(id)
);

-- Modificaciones de las tablas post-implementacion
-- ================================================

-- Legajo único para la tabla [dbCureSA].[Medico]

IF OBJECT_ID('dbCureSA.UQ_nroMatricula') IS NOT NULL
	ALTER TABLE [dbCureSA].[Medico] DROP CONSTRAINT "UQ_nroMatricula";

ALTER TABLE [dbCureSA].[Medico]
	ADD CONSTRAINT "UQ_nroMatricula" UNIQUE (nroMatricula);
GO

-- CONTRAINT UNIQUE para (prestador - plan) único en vez de prestador [dbCureSA].[Prestador]
-- ya que esto imposibilitaba la carga de distintos planes para un solo prestador
IF OBJECT_ID('dbCureSA.UQ_nombrePrestador') IS NOT NULL
	ALTER TABLE [dbCureSA].[Prestador] DROP CONSTRAINT [UQ_nombrePrestador];
GO

ALTER TABLE dbCureSA.Prestador
	ADD CONSTRAINT [UQ_nombrePrestador] UNIQUE (nombre,[plan])
GO

-- LARGO de COLUMNA direccion para la tabla [dbCureSA].[Sede]
ALTER TABLE dbCureSA.Sede
	ALTER COLUMN direccion VARCHAR(100) NOT NULL;
GO

-- MODIFICACIONES TABLA PACIENTE
-- Cambio de relacion entre las tablas Paciente y Cobertura.
-- La FK de la relacion pasa hacia la tabla Cobertura
ALTER TABLE dbCureSA.Cobertura
	add idPaciente INT
GO

ALTER TABLE dbCureSA.Cobertura
	add constraint FK_idPacienteCobertura FOREIGN KEY (idPaciente) REFERENCES dbCureSA.Paciente(idHistoriaClinica)
GO

IF OBJECT_ID('dbCureSA.FK_idCoberturaPac') IS NOT NULL
	ALTER TABLE [dbCureSA].[Paciente] DROP CONSTRAINT [FK_idCoberturaPac];
GO

ALTER TABLE dbCureSA.Paciente
	DROP COLUMN FK_idCobertura
GO

-- Cambio de tamaño del nroDoc y la constraint check que lo valida y el constraint unique
IF OBJECT_ID('dbCureSA.CK_nroDoc') IS NOT NULL
	ALTER TABLE [dbCureSA].[Paciente] DROP CONSTRAINT [CK_nroDoc];
GO


IF OBJECT_ID('dbCureSA.UQ_tipoDoc_docPac') IS NOT NULL
	ALTER TABLE [dbCureSA].[Paciente] DROP CONSTRAINT [UQ_tipoDoc_docPac];
GO


ALTER TABLE dbCureSA.Paciente
	ALTER COLUMN nroDoc varchar(10) NOT NULL
GO

ALTER TABLE dbCureSA.Paciente
	ADD CONSTRAINT CK_nroDoc CHECK (
		nroDoc NOT LIKE '[^0-9]'				-- Debe ser unicamente dígitos.
		AND LEN(nroDoc) > 7						-- Debe ser mayor a 7 dígitos.
	)
GO

ALTER TABLE dbCureSA.Paciente
	ADD CONSTRAINT UQ_tipoDoc_docPac UNIQUE (tipoDoc,nroDoc)
GO

-- Adicion de un campo mayor para tel fijo y reajuste en la contraint CHECK
IF OBJECT_ID('dbCureSA.CK_telFijo') IS NOT NULL
	ALTER TABLE [dbCureSA].[Paciente] DROP CONSTRAINT [CK_telFijo];
GO

ALTER TABLE dbCureSA.Paciente
	ALTER COLUMN telFijo CHAR(15)
GO

ALTER TABLE dbCureSA.Paciente
	ADD	CONSTRAINT CK_telFijo CHECK(
	    LEN(telFijo) >= 10						-- Debe tener al menos 10 caracteres.
	    AND LEN(telFijo) <= 15					-- Debe tener como máximo 13 caracteres.
		--AND ISNUMERIC(telFijo) = 1			-- Debe ser numérico.
		AND telFijo NOT LIKE '[^(0-9)]'			-- Debe contener solo dígitos numéricos.
	)
GO

-- MODIFICACIONES TABLA DOMICILIO
-- Cambio de tipo de dato para el codigo postal
ALTER TABLE dbCureSA.Domicilio
	ALTER COLUMN cp int;
GO

-- CONSTRAINT de EstadoTurno que prohíbe la entrada de nuevo estados
IF OBJECT_ID('dbCureSA.[CK_estadoTurno]') IS NOT NULL
	ALTER TABLE dbCureSA.EstadoTurno DROP CONSTRAINT CK_estadoTurno;
GO

ALTER TABLE dbCureSA.EstadoTurno
	ADD CONSTRAINT CK_estadoTurno CHECK(
		UPPER(estado) = 'ATENDIDO'
		OR UPPER(estado) = 'AUSENTE'
		OR UPPER(estado) = 'CANCELADO'
		OR UPPER(estado) = 'PENDIENTE'
	)
GO

-- Actualización de columnas de ESTUDIO para albergar los datos del JSON correctamente
ALTER TABLE dbCureSA.Estudio
    ALTER COLUMN nombreEstudio VARCHAR(100);
GO

ALTER TABLE dbCureSA.Estudio
	ADD costo DECIMAL(8,2);
GO

-- MODIFICACION TABLA COBERTURA
-- Actualización CONSTRAINT UNIQUE para permitir la carga de Planes distintos según el prestador
IF OBJECT_ID('dbCureSA.[UQ_nroSocioCobertura]') IS NOT NULL
	ALTER TABLE [dbCureSA].[Cobertura] DROP CONSTRAINT [UQ_nroSocioCobertura];
GO

ALTER TABLE [dbCureSA].[Cobertura] 
	ADD CONSTRAINT [UQ_nroSocioCobertura] UNIQUE ([idPrestador],[nroSocio] ASC )
GO

-- MODIFICACION TABLA DOMICILIO
ALTER TABLE dbCureSA.Domicilio
	ALTER COLUMN numero VARCHAR(25);
GO

-- Creación columna activo tabla DOMICILIO
IF EXISTS ( SELECT 1 FROM sys.all_columns
			WHERE object_id = OBJECT_ID('[dbCureSA].[Domicilio]')
			AND name = 'activo')
	ALTER TABLE dbCureSA.Domicilio DROP COLUMN activo;

ALTER TABLE dbCureSA.Domicilio ADD activo BIT DEFAULT 1;
GO

-- Creación columna activo tabla USUARIO
IF EXISTS ( SELECT 1 FROM sys.all_columns
			WHERE object_id = OBJECT_ID('[dbCureSA].[Usuario]')
			AND name = 'activo')
	ALTER TABLE dbCureSA.Usuario DROP COLUMN activo;

ALTER TABLE dbCureSA.Usuario ADD activo BIT DEFAULT 1;
GO

-- Creación columna activo tabla Estudio
IF EXISTS ( SELECT 1 FROM sys.all_columns
			WHERE object_id = OBJECT_ID('[dbCureSA].[Estudio]')
			AND name = 'activo')
	ALTER TABLE dbCureSA.Estudio DROP COLUMN activo;

ALTER TABLE dbCureSA.Estudio ADD activo BIT DEFAULT 1;
GO

-- Creación columna activo tabla EstadoTurno
IF EXISTS ( SELECT 1 FROM sys.all_columns
			WHERE object_id = OBJECT_ID('[dbCureSA].[EstadoTurno]')
			AND name = 'activo')
	ALTER TABLE dbCureSA.EstadoTurno DROP COLUMN activo;

ALTER TABLE dbCureSA.EstadoTurno ADD activo BIT DEFAULT 1;
GO
-- Creación columna activo tabla TipoTurno
IF EXISTS ( SELECT 1 FROM sys.all_columns
			WHERE object_id = OBJECT_ID('[dbCureSA].[TipoTurno]')
			AND name = 'activo')
	ALTER TABLE dbCureSA.TipoTurno DROP COLUMN activo;

ALTER TABLE dbCureSA.TipoTurno ADD activo BIT DEFAULT 1;
GO
-- Creación columna activo tabla Sede
IF EXISTS ( SELECT 1 FROM sys.all_columns
			WHERE object_id = OBJECT_ID('[dbCureSA].[Sede]')
			AND name = 'activo')
	ALTER TABLE dbCureSA.Sede DROP COLUMN activo;

ALTER TABLE dbCureSA.Sede ADD activo BIT DEFAULT 1;
GO

-- Creación columna activo tabla Especialidad
IF EXISTS ( SELECT 1 FROM sys.all_columns
			WHERE object_id = OBJECT_ID('[dbCureSA].[Especialidad]')
			AND name = 'activo')
	ALTER TABLE dbCureSA.Especialidad DROP COLUMN activo;

ALTER TABLE dbCureSA.Especialidad ADD activo BIT DEFAULT 1;

-- CREACIÓN DE STORE PROCEDURES
-- ===========================================
GO
-- Procedures genéricos para insertar datos
CREATE OR ALTER PROCEDURE [spCureSA].[InsertarLog]
	@texto VARCHAR(250),
	@modulo VARCHAR(15)
AS
BEGIN
	SET NOCOUNT ON;

	IF LTRIM(RTRIM(@modulo)) = ''
		SET @texto = 'N/A'

	INSERT INTO logCureSA.Registro (texto, modulo)
	VALUES (@texto, @modulo)
END

GO
CREATE OR ALTER PROCEDURE [spCureSA].[ModificarDatos]
    @nombreTabla NVARCHAR(128),
    @columnasAActualizar NVARCHAR(MAX),
    @valoresNuevos NVARCHAR(MAX),
    @condicion NVARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @SQL NVARCHAR(MAX);
	DECLARE @texto VARCHAR(250);
	DECLARE @modulo VARCHAR(15);

    SET @SQL = N'UPDATE dbCureSA.' + QUOTENAME(@nombreTabla) +
               N' SET ' + @columnasAActualizar +
               N' = ' + @valoresNuevos +
               N' WHERE ' + @condicion;

    EXEC sp_executesql @SQL;

	IF @@ROWCOUNT <> 0
	BEGIN
		PRINT('Modificación exitosa');
		SET @texto = 'Modificación de datos en la tabla: ' + @nombreTabla + '. Donde: ' + @condicion;
		SET @modulo = 'MODIFICACIÓN';
		EXEC spCureSA.InsertarLog @texto, @modulo;
	END
	ELSE
	BEGIN
		PRINT('Error en la Modificación.');
	END

	SET NOCOUNT OFF;
END;
GO

CREATE OR ALTER PROCEDURE [spCureSA].[InsertarDatos]
    @nombreTabla NVARCHAR(128),
    @columnas NVARCHAR(MAX),
    @valores NVARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(MAX);
	DECLARE @texto VARCHAR(250);
	DECLARE @modulo VARCHAR(15);

    SET @SQL = N'INSERT INTO dbCureSA.' + QUOTENAME(@nombreTabla) +
               N' (' + @columnas + N') ' +
               N'VALUES' + @valores;

    EXEC sp_executesql @SQL;

	IF @@ROWCOUNT <> 0
	BEGIN
		PRINT('Inserción exitosa');
		SET @texto = 'Inserción de datos en la tabla: ' + @nombreTabla + '. Con: ' + @valores;
		SET @modulo = 'INSERCIÓN';
		EXEC spCureSA.InsertarLog @texto, @modulo;
	END
	ELSE
	BEGIN
		PRINT('Error en la Inserción.');
	END

	SET NOCOUNT OFF;
END;

GO

CREATE OR ALTER PROCEDURE [spCureSA].[EliminarDatos]
    @nombreTabla NVARCHAR(128),
    @condicion NVARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(MAX);
	DECLARE @texto VARCHAR(250);
    DECLARE @modulo VARCHAR(15);

    SET @SQL = N'DELETE FROM dbCureSA.' + QUOTENAME(@nombreTabla) +
               N' WHERE ' + @condicion;

    EXEC sp_executesql @SQL;

	IF @@ROWCOUNT <> 0
	BEGIN
		PRINT('Eliminación exitosa');
		SET @texto = 'Eliminación de datos en la tabla: ' + @nombreTabla + '. Donde: ' + @condicion;
		SET @modulo = 'ELIMINACIÓN';
		EXEC spCureSA.InsertarLog @texto, @modulo;
	END
	ELSE
	BEGIN
		PRINT('Error en la Eliminación.');
	END

	SET NOCOUNT OFF;
END;

-- Procedures para Importar datos masivos según su archivo fuente

-- Insertar masivamente los médicos, requiere primero ejecutarse el procedure de Especialidad

-- Ambos procedures (spCureSA.insertarMasivoEspecialidad, spCureSA.insertarMasivoMedico) esperan un archivo CSV con una fila de encabezado y con los siguientes parámetros:
-- Nombre;Apellidos;Especialidad:Número de colegiado
-- Su único parametro es @rutacsv que requiere el el path del archivo a cargar
GO
CREATE OR ALTER PROC spCureSA.insertarMasivoEspecialidad @rutacsv NVARCHAR(300)
AS
	SET NOCOUNT ON;
	-- Tabla temporal para realizar el proceso de ETL
	
	IF OBJECT_ID('tempdb..#csvMedico') IS NOT NULL
		DROP TABLE #csvMedico;
	
	
	CREATE TABLE #csvMedico (
		apellido VARCHAR(50) NOT NULL,
		nombre VARCHAR(50) NOT NULL,
		especialidad VARCHAR(50) NOT NULL,
		nroMatricula VARCHAR(50) NOT NULL,
	)

	-- Declarar variables
	DECLARE @BULK_INSERT_QUERY AS NVARCHAR(MAX)
		, @ilog AS VARCHAR(250)
		, @reg AS INT;
	
	-- Insertar valores del csv en la tabla temporal
	SET @BULK_INSERT_QUERY = N'BULK INSERT #csvMedico FROM ''' + @rutacsv + N''' WITH(CHECK_CONSTRAINTS, CODEPAGE = ''65001'', FIRSTROW = 2, FIELDTERMINATOR = '';'')'
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		EXEC sp_executesql @BULK_INSERT_QUERY

		-- TRANSFORMACION DE DATOS
		UPDATE #csvMedico
		SET especialidad = UPPER(especialidad)
		
		UPDATE #csvMedico
		SET nombre = UPPER(nombre) 

		INSERT INTO dbCureSA.Especialidad (nombre)
		SELECT DISTINCT a.especialidad COLLATE Modern_Spanish_CI_AI FROM #csvMedico a
		WHERE NOT EXISTS (SELECT 1 FROM dbCureSA.Especialidad b
							WHERE a.especialidad = b.nombre)
		
		SET @reg = @@ROWCOUNT;

		SET @ilog = '[dbCureSA.Especialidad] - ' + CAST(@reg AS varchar) + ' especialidades nuevas';
		PRINT @ilog;

		EXEC spCureSA.InsertarLog @texto = @ilog, @modulo = '[INSERT]'

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		PRINT '[ERROR] - NO SE HA PODIDO IMPORTAR NUEVAS ESPECIALIDADES'
		PRINT '[ERROR] - ' + '[LINE]: ' + ERROR_LINE() + ' - [MSG]: ' + ERROR_MESSAGE()
		
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION

	END CATCH

	DROP TABLE #csvMedico
	SET NOCOUNT OFF;

GO

CREATE OR ALTER PROC spCureSA.insertarMasivoMedico @rutacsv NVARCHAR(300)
AS
	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#csvMedic') IS NOT NULL
		DROP TABLE #csvMedic;

	CREATE TABLE #csvMedic (
		apellido VARCHAR(50) NOT NULL,
		nombre VARCHAR(50) NOT NULL,
		especialidad VARCHAR(50) NOT NULL,
		nroMatricula VARCHAR(50) NOT NULL
	)
	
	DECLARE @BULK_INSERT_QUERY AS NVARCHAR(MAX)
		, @ilog AS NVARCHAR(250)
		, @reg AS INT
	
	-- Bulk insert a la tabla temporal que servirá parte del proceso del ETL.
	SET @BULK_INSERT_QUERY = N'BULK INSERT #csvMedic FROM ''' + @rutacsv + N''' WITH(CHECK_CONSTRAINTS, CODEPAGE = ''65001'', FIRSTROW = 2, FIELDTERMINATOR = '';'')'
	

	BEGIN TRY
		BEGIN TRANSACTION
		EXEC sp_executesql @BULK_INSERT_QUERY

		UPDATE #csvMedic
		SET nombre = RTRIM(LTRIM(nombre))

		UPDATE #csvMedic
		SET apellido = LTRIM(SUBSTRING(APELLIDO,CHARINDEX('. ', apellido)+1,LEN(apellido)))

		-- Insertar Médicos
		INSERT INTO dbCureSA.Medico (idEspecialidad, nombre, apellido, nroMatricula, activo)
		SELECT ds.id
			, m.nombre
			, m.apellido
			, m.nroMatricula
			, 1
		FROM #csvMedic m 
		JOIN dbCureSA.Especialidad ds ON m.especialidad = ds.nombre
		WHERE NOT EXISTS (
			SELECT 1 FROM dbCureSA.Medico b
			WHERE m.nroMatricula = b.nroMatricula
		)

		SET @reg = @@ROWCOUNT;

		SET @ilog = N'[dbCureSA.Medico] - ' + CAST(@reg AS VARCHAR)+ N' médicos nuevos';
		PRINT @ilog;

		EXEC spCureSA.InsertarLog @texto = @ilog, @modulo = '[INSERT]'
		
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		PRINT N'[ERROR] - NO SE HA PODIDO IMPORTAR NUEVOS MÉDICOS'
		PRINT N'[ERROR] - ' +'[LINE]: ' + CAST(ERROR_LINE() AS VARCHAR)+ ' - [MSG]: ' + CAST(ERROR_MESSAGE() AS VARCHAR)

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION

	END CATCH
	DROP TABLE #csvMedic
	
	SET NOCOUNT OFF;
GO

-- Insertar masivamente las sedes

-- Se espera un archivo CSV con una fila de encabezado y con los siguientes parámetros:
-- Sede;Direccion;Localidad;Provincia
-- Su único parametro es @rutacsv que requiere el el path del archivo a cargar
CREATE OR ALTER PROCEDURE [spCureSA].[insertarMasivoSede] @rutacsv as NVARCHAR(300)
AS
	SET NOCOUNT ON;
	-- Tabla temporal para realizar la transformacion de datos
	IF OBJECT_ID('tempdb..#csvSedes') IS NOT NULL
		DROP TABLE #csvSedes;

	CREATE TABLE #csvSedes(
		sede VARCHAR(50),
		direccion VARCHAR(200),
		localidad VARCHAR(50),
		provincia VARCHAR(50)
	)

	DECLARE @BULK_INSERT_QUERY AS NVARCHAR(MAX)
		, @ilog AS VARCHAR(250)
		, @registrosAniadidos as SMALLINT;
	
	-- Insertar valores del csv en la tabla temporal
	SET @BULK_INSERT_QUERY = N'BULK INSERT #csvSedes FROM ''' + @rutacsv + N''' WITH(CHECK_CONSTRAINTS, CODEPAGE = ''65001'', FIRSTROW = 2, FIELDTERMINATOR = '';'')'
	
	BEGIN TRY
		BEGIN TRANSACTION
		-- Importar datos a la tabla temporal
		EXEC sp_sqlexec @BULK_INSERT_QUERY

		-- transformar los datos
		UPDATE #csvSedes
		SET sede = TRIM(sede)

		UPDATE #csvSedes
		SET direccion = TRIM(direccion) + ', ' + TRIM(localidad) + ', ' + TRIM(provincia)

		-- Insertar datos transformados a la tabla correspondiente.
		INSERT INTO dbCureSA.Sede (nombre, direccion)
		SELECT sede, direccion
		FROM #csvSedes a
		WHERE NOT EXISTS (SELECT 1 FROM dbCureSA.Sede b
							WHERE a.sede = b.nombre AND a.direccion = b.direccion)

		-- Ingresar datos al log
		SET @registrosAniadidos = @@ROWCOUNT

		SET @ilog = N'[dbCureSA.Sede] - ' + CAST(@registrosAniadidos AS nvarchar) + N' sedes nuevas';
		PRINT @ilog;

		EXEC spCureSA.InsertarLog @texto = @ilog, @modulo = '[INSERT]'

		COMMIT TRANSACTION

	END TRY
	BEGIN CATCH
		PRINT '[ERROR] - NO SE HA PODIDO IMPORTAR NUEVAS SEDES'
		PRINT '[ERROR] - ' +'[LINE]: ' + CAST(ERROR_LINE() AS VARCHAR) + ' - [MSG]: ' + CAST(ERROR_MESSAGE() AS VARCHAR)
		
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION

	END CATCH

	DROP TABLE #csvSedes;

	SET NOCOUNT OFF;
GO

-- Insertar masivamente los prestadores

-- Se espera un archivo CSV con una fila de encabezado y con los siguientes parámetros:
-- Prestador;Plan;;
-- Su único parametro es @rutacsv que requiere el el path del archivo a cargar

CREATE OR ALTER PROCEDURE [spCureSA].[insertarMasivoPrestador] @rutacsv as NVARCHAR(300)
AS
	SET NOCOUNT ON;
	-- Tabla temporal para realizar la transformacion de datos
	
	IF OBJECT_ID('tempdb..#csvPrestador') IS NOT NULL
		DROP TABLE #csvPrestador;
	
	CREATE TABLE #csvPrestador(
		prestador VARCHAR(50),
		[plan] VARCHAR(50),
		relleno1 VARCHAR(50),
		relleno2 VARCHAR(50)
	)

	DECLARE @BULK_INSERT_QUERY AS NVARCHAR(MAX)
		, @ilog AS VARCHAR(250)
		, @registrosAniadidos as SMALLINT;
	
	-- Insertar valores del csv en la tabla temporal
	SET @BULK_INSERT_QUERY = N'BULK INSERT #csvPrestador FROM ''' + @rutacsv + N''' WITH(CHECK_CONSTRAINTS, CODEPAGE = ''65001'', FIRSTROW = 2, FIELDTERMINATOR = '';'')'
	
	BEGIN TRY
		-- Importar datos a la tabla temporal
		EXEC sp_sqlexec @BULK_INSERT_QUERY
		BEGIN TRANSACTION
		-- Insertar datos transformados a la tabla correspondiente.
		UPDATE #csvPrestador
		SET prestador = UPPER(prestador);

		UPDATE #csvPrestador
		SET [plan] = TRIM(CASE
							WHEN CHARINDEX(UPPER(prestador),UPPER([Plan]),0) = 0 THEN [plan]
							ELSE SUBSTRING([plan],0,CHARINDEX(UPPER(prestador),UPPER([Plan]),0)) + SUBSTRING([plan],CHARINDEX(UPPER(prestador),UPPER([Plan]),0)+LEN(prestador) + 1,50)
			  END);

		INSERT INTO dbCureSA.Prestador (nombre, [plan], activo)
		SELECT prestador AS [nombre]
			, [plan] AS [plan]
			, 1
		FROM #csvPrestador a
		WHERE NOT EXISTS(
			SELECT 1 FROM dbCureSA.Prestador b
			WHERE a.prestador = b.nombre
			AND a.[plan] = b.[plan]
		)

		-- Ingresar datos al log
		SET @registrosAniadidos = @@ROWCOUNT

		SET @ilog = N'[dbCureSA.Prestador] - ' + CAST(@registrosAniadidos AS nvarchar) + N' prestadores nuevos';
		PRINT @ilog;
		
		EXEC spCureSA.InsertarLog @texto = @ilog, @modulo = '[INSERT]'
		
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		PRINT '[ERROR] - NO SE HA PODIDO IMPORTAR NUEVOS PRESTADORES'
		PRINT '[ERROR] - ' +'[LINE]: ' + CAST(ERROR_LINE() AS VARCHAR) + ' - [MSG]: ' + CAST(ERROR_MESSAGE() AS VARCHAR)
		
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION
	END CATCH

	DROP TABLE #csvPrestador;

	SET NOCOUNT OFF;
GO

-- Insertar usuarios masivamente
-- El procedure es ejecutado sin ningún parámetro y creará los usuarios de aquellos pacientes
-- que no posean uno.

-- Store Procedure para dar de alta los nuevos usuarios. Siempre y cuando no existan en USUARIOS.
CREATE OR ALTER PROCEDURE spCureSA.insertarMasivoUsuario
AS
	SET NOCOUNT ON;

	DECLARE @ilog AS VARCHAR(250), @incorporaciones AS INT;

	BEGIN TRY
		BEGIN TRANSACTION

		-- Dar de alta los usuarios siempre y cuando ya no hayan sido creados previamente.
		INSERT INTO dbCureSA.Usuario (idUsuario, idPaciente, contrasenia, fechaCreacion)
		SELECT	idHistoriaClinica 											AS idUsuario
			,	nroDoc														AS idPaciente
			,	TRIM(LEFT(genero,1)) + TRIM(nroDoc) + LEFT(apellido,1)
				+ LEFT(nombre,1)											AS contrasenia
			,	CAST(GETDATE() AS date)										AS fechaCreacion
		FROM dbCureSA.Paciente pa
		WHERE NOT EXISTS (SELECT 1 FROM dbCureSA.Usuario us
						WHERE pa.idHistoriaClinica = us.idUsuario)
		
		SET @incorporaciones = @@ROWCOUNT;

		IF @incorporaciones < 1
			SET @ilog = '[dbCureSA.Usuario] - No existen nuevos usuarios' 
		ELSE
			SET @ilog = '[dbCureSA.Usuario] - ' + CAST(@incorporaciones AS VARCHAR) + ' nuevos usuarios.'
		
		PRINT @ilog
		EXEC spCureSA.InsertarLog @texto = @ilog, @modulo = '[INSERT]'

		COMMIT TRAN
	END TRY
	BEGIN CATCH
		PRINT '[ERROR] - NO SE HA PODIDO INCORPORAR USUARIOS POR PROBLEMAS EXTERNOS'
		PRINT '[ERROR] - ' +'[LINE]: ' + CAST(ERROR_LINE() AS VARCHAR) + ' - [MSG]: ' + ERROR_MESSAGE()
		
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN

	END CATCH
	
	SET NOCOUNT OFF;
GO

-- Insertar masivamente los pacientes y domicilios

-- Los procedures deben ejecutarse por separado, primero [spCureSA].[insertarMasivoPaciente] y luego [spCureSA].[insertarMasivoDomicilio]
-- Se espera un archivo CSV con una fila de encabezado y con los siguientes parámetros:
-- Nombre ;Apellido;Fecha de nacimiento;tipo Documento;Nro documento;Femenino;genero;Telefono fijo;Nacionalidad;Mail;Calle y Nro;Localidad;Provincia
-- Su único parametro es @rutacsv que requiere el el path del archivo a cargar

CREATE OR ALTER PROCEDURE [spCureSA].[insertarMasivoPaciente] @rutacsv as NVARCHAR(300)
AS
	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#TempPacientes') IS NOT NULL
		DROP TABLE #TempPacientes;


	CREATE TABLE #TempPacientes (
        nombre VARCHAR(50) NOT NULL,
        apellido VARCHAR(50) NOT NULL,
        fecNac VARCHAR(10),
        tipoDoc CHAR(3) NOT NULL,
        nroDoc CHAR(15) NOT NULL,
        sexo VARCHAR(10) NOT NULL,
        genero CHAR(10) NOT NULL,
		telFijo CHAR(14) NOT NULL,
        nacionalidad VARCHAR(25) NOT NULL,
        mail VARCHAR(50),
		calleyNro varchar(50),
		localidad varchar(50),
		provincia varchar(25)
    )

	DECLARE @BULK_INSERT_QUERY AS NVARCHAR(MAX)
		, @ilog AS NVARCHAR(250)
		, @reg AS INT;
	
	---- Bulk insert a la tabla temporal que servirá parte del proceso del ETL.
	SET @BULK_INSERT_QUERY = N'BULK INSERT #TempPacientes FROM ''' + @rutacsv + N''' WITH(CHECK_CONSTRAINTS, CODEPAGE = ''65001'', FIRSTROW = 2, FIELDTERMINATOR = '';'' , ROWTERMINATOR = ''\n'')'
	
	BEGIN TRY
		BEGIN TRANSACTION
		EXEC sp_executesql @BULK_INSERT_QUERY;
		-- select * from #TempPacientes
		WITH datos (nom, ape, fna, tip, doc, sex, gen, nac, mai, tel, dat) AS
		(
			SELECT
			ltrim(p.nombre)
			,ltrim(p.apellido)
			,CONVERT(DATE, p.fecNac, 103)   -- Convertir la fecha al formato correcto (dd/mm/yyyy)
			,LTRIM(p.tipoDoc)
			,LTRIM(p.nroDoc)
			,CASE WHEN sexo = UPPER('Femenino') THEN 'F' ELSE 'M' END  -- Convertir 'Femenino' a 'F' y 'Masculino' a 'M'
			,LTRIM(p.genero)
			,LTRIM(p.nacionalidad)
			,LTRIM(p.mail)
			,LTRIM(p.telFijo)
			,GETDATE()
			FROM #TempPacientes p
		)
		INSERT INTO dbCureSA.Paciente (nombre, apellido, fecNac, tipoDoc, nroDoc, sexo, genero, nacionalidad, mail, telFijo, fechaReg)
		SELECT
				nom
			,	ape
			,	fna   -- Convertir la fecha al formato correcto (dd/mm/yyyy)
			,	tip
			,	Doc
			,	sex
			,	gen
			,	nac
			,	mai
			,	tel
			,	dat
		FROM datos p
		WHERE NOT EXISTS (
			SELECT 1 FROM dbCureSA.Paciente b
			WHERE p.tip = b.tipoDoc
			AND p.doc = b.nroDoc
		)

		SET @reg = @@ROWCOUNT;

		SET @ilog = N'[dbCureSA.Paciente] - ' + CAST(@reg AS VARCHAR)+ N' pacientes nuevos';
		PRINT @ilog;

		EXEC spCureSA.InsertarLog @texto = @ilog, @modulo = '[INSERT]'
		
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		PRINT N'[ERROR] - NO SE HA PODIDO IMPORTAR NUEVOS PACIENTES'
		PRINT N'[ERROR] - ' +'[LINE]: ' + CAST(ERROR_LINE() AS VARCHAR) + ' - [MSG]: ' + CAST(ERROR_MESSAGE() AS VARCHAR)

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION

	END CATCH
	DROP TABLE #TempPacientes
	
	SET NOCOUNT OFF;
GO


CREATE OR ALTER PROCEDURE [spCureSA].[insertarMasivoDomicilio] @rutacsv as NVARCHAR(300)
AS
	SET NOCOUNT ON;
	
	IF OBJECT_ID('tempdb..#TempPacientes') IS NOT NULL
		DROP TABLE #TempPacientes;
	
	CREATE TABLE #TempPacientes (
        nombre VARCHAR(50) NOT NULL,
        apellido VARCHAR(50) NOT NULL,
        fecNac VARCHAR(10),
        tipoDoc CHAR(3) NOT NULL,
        nroDoc CHAR(15) NOT NULL,
        sexo VARCHAR(10) NOT NULL,
        genero CHAR(10) NOT NULL,
		telFijo CHAR(14) NOT NULL,
        nacionalidad VARCHAR(25) NOT NULL,
        mail VARCHAR(50),
		calleCompleta varchar(50),
		loc varchar(50),
		prov varchar(25)
    )

	DECLARE @BULK_INSERT_QUERY AS NVARCHAR(MAX)
		, @ilog AS NVARCHAR(250)
		, @reg AS INT;
	
	---- Bulk insert a la tabla temporal que servirá parte del proceso del ETL.
	SET @BULK_INSERT_QUERY = N'BULK INSERT #TempPacientes FROM ''' + @rutacsv + N''' WITH(CHECK_CONSTRAINTS, CODEPAGE = ''65001'', FIRSTROW = 2, FIELDTERMINATOR = '';'' , ROWTERMINATOR = ''\n'')'
	
	BEGIN TRY
		BEGIN TRANSACTION
		EXEC sp_executesql @BULK_INSERT_QUERY;
		
		WITH datos (his, cal, num, pro, loc) AS (
			SELECT
				pa.idHistoriaClinica
				,SUBSTRING(RTRIM(p.calleCompleta), 1, LEN(RTRIM(p.calleCompleta)) - CHARINDEX(' ', REVERSE(RTRIM(p.calleCompleta)))) as calle
				,SUBSTRING(RTRIM(p.calleCompleta), LEN(RTRIM(p.calleCompleta)) - CHARINDEX(' ', REVERSE(RTRIM(p.calleCompleta)), 0) + 2, 10) as numero
				,ltrim(p.prov)
				,ltrim(p.loc)
			FROM #TempPacientes p
			JOIN dbCureSA.Paciente pa ON pa.nroDoc = p.nroDoc COLLATE Modern_Spanish_CI_AS AND pa.tipoDoc COLLATE Modern_Spanish_CI_AS = p.tipoDoc COLLATE Modern_Spanish_CI_AS
		)
		INSERT INTO dbCureSA.Domicilio (idPaciente,calle, numero, provincia, localidad)
		SELECT
				his
			,	cal
			,	num
			,	pro
			,	loc
		FROM datos d
		WHERE NOT EXISTS (
			SELECT 1 FROM dbCureSA.Domicilio b
			WHERE d.his = b.idPaciente
			AND d.cal = b.calle
			AND d.num = b.numero
		)
		
		SET @reg = @@ROWCOUNT;
		SET @ilog = N'[dbCureSA.Domicilio] - ' + CAST(@reg AS VARCHAR)+ N' domicilios nuevos';

		PRINT @ilog;

		EXEC spCureSA.InsertarLog @texto = @ilog, @modulo = '[INSERT]'
		
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		PRINT N'[ERROR] - NO SE HA PODIDO IMPORTAR NUEVOS DOMICILIOS'
		PRINT N'[ERROR] - ' +'[LINE]: ' + CAST(ERROR_LINE() AS VARCHAR) + ' - [MSG]: ' + ERROR_MESSAGE()

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION

	END CATCH
	DROP TABLE #TempPacientes
	
	SET NOCOUNT OFF;
GO

-- Insertar masivamente las autorizaciones

-- Se espera un archivo JSON con una fila de encabezado y con los siguientes parámetros:
/* {
  "_id": {
    "$oid": "string"
  },
  "Area": "string",
  "Estudio": "string",
  "Prestador": "string",
  "Plan": "string",
  "Porcentaje Cobertura": int,
  "Costo": int,
  "Requiere autorizacion": bool
}
*/
-- Su único parametro es @rutajson que requiere el el path del archivo a cargar

CREATE OR ALTER PROCEDURE [spCureSA].[insertarMasivoAutorizacion] @rutajson as NVARCHAR(300)
AS
	SET NOCOUNT ON;
	-- Tabla temporal para realizar la transformacion de datos
	IF OBJECT_ID('tempdb..#datosJSON') IS NOT NULL
		DROP TABLE #datosJSON;

	CREATE TABLE #datosJSON (COL NVARCHAR(MAX))
	
	DECLARE @BULK_INSERT_QUERY AS NVARCHAR(MAX)
		, @ilog AS VARCHAR(250)
		, @registrosAniadidos as SMALLINT;
	
	-- Insertar valores del csv en la tabla temporal
	SET @BULK_INSERT_QUERY = N'BULK INSERT #datosJSON FROM ''' + @rutajson + N''' WITH ( CODEPAGE = ''65001'')'
	
	BEGIN TRY
		BEGIN TRANSACTION
		-- Importar datos a la tabla temporal
		EXEC sp_sqlexec @BULK_INSERT_QUERY;

		-- Insertar datos transformados a la tabla correspondiente.
		WITH datos (area,estudio,prestador,pl,cob,costo,autor) as (
		SELECT UPPER(AREA)
			,	UPPER(ESTUDIO)
			,	UPPER(prestador)
			,	TRIM(CASE
					WHEN CHARINDEX(UPPER(prestador),UPPER([Plan]),0) = 0 THEN [plan]
					ELSE SUBSTRING([plan],0,CHARINDEX(UPPER(prestador),UPPER([Plan]),0)) + SUBSTRING([plan],CHARINDEX(UPPER(prestador),UPPER([Plan]),0)+LEN(prestador) + 1,50)
				END)
			,	COB
			,	COSTO
			,	AUTOR
		FROM #datosJSON
		CROSS APPLY OPENJSON(COL) with(
			AREA  VARCHAR(50) '$.Area',
			ESTUDIO NVARCHAR(100) '$.Estudio',
			PRESTADOR NVARCHAR(50) '$.Prestador',
			[PLAN] VARCHAR(50) '$.Plan',
			COB INT '$."Porcentaje Cobertura"',
			COSTO INT '$.Costo',
			autor BIT '$."Requiere autorizacion"'
		) as book 
		WHERE AREA IS NOT NULL)
		INSERT INTO dbCureSA.Autorizacion (idPrestador, area, nombreEstudio, porcCobertura, costo
		, autorizacion)
		SELECT p.id								AS [FK_Prestador]
			,	d.area							AS [Area]
			,	d.estudio						AS [Nombre Estudio]
			,	CAST(d.cob AS decimal)/100		AS [Porc. Cobertura]
			,	CAST(d.costo AS decimal(8,2))	AS [Costo]
			,	d.autor							AS [Autorizacion]
		FROM datos d
		JOIN dbCureSA.Prestador p ON p.nombre = d.prestador and p.[plan] = d.pl
		WHERE NOT EXISTS (
			SELECT 1 
			FROM dbCureSA.Autorizacion a
			WHERE p.id = a.idPrestador
			AND d.area = a.area
			AND d.estudio = a.nombreEstudio
			);
		
		-- Ingresar datos al log
		SET @registrosAniadidos = @@ROWCOUNT;

		SET @ilog = N'[dbCureSA.Autorizacion] - ' + CAST(@registrosAniadidos AS nvarchar) + N' autorizaciones nuevas';
		PRINT @ilog	
		
		EXEC spCureSA.InsertarLog @texto = @ilog, @modulo = '[INSERT]'

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		PRINT '[ERROR] - NO SE HA PODIDO IMPORTAR NUEVAS AUTORIZACIONES'
		PRINT '[ERROR] - ' +'[LINE]: ' + CAST(ERROR_LINE() AS VARCHAR) + ' - [MSG]: ' + ERROR_MESSAGE()
		
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION
	END CATCH

	DROP TABLE #datosJSON;

	SET NOCOUNT OFF;
GO	
-- Procedure para exportar los turnos
-- ========================================

-- Exportar Turnos requiere como parámetro la obra social en cuestión y las fechas desde y hasta (turnos) para exportar.
GO
CREATE OR ALTER PROCEDURE spCureSA.ExportarTrunos
	@obraSocial AS VARCHAR(50),
	@fechaInicio AS DATE,
	@fechaFin AS DATE
AS
BEGIN
	SET NOCOUNT ON;

    
	SELECT	p.nroDoc						AS [DNI]
		,	p.apellido + ', ' + p.nombre	AS [Apyn_Paciente]
		,	m.apellido + ', ' + m.nombre	AS [Apyn_Medico]
		,	m.nroMatricula					AS [Nro_Matrícula]
		,	rt.fecha						AS [Fecha_Atendido]
		,	rt.hora							AS [Hora_Atendido]
		,	e.nombre						AS [Especialidad]
	FROM dbCureSA.ReservaTurno rt
		INNER JOIN dbCureSA.Paciente p on rt.idPaciente = p.idHistoriaClinica
		INNER JOIN dbCureSA.EstadoTurno et ON rt.idEstado = et.id
		INNER JOIN dbCureSA.Cobertura c ON c.idPaciente = p.idHistoriaClinica
		INNER JOIN dbCureSA.Prestador pr ON c.idPrestador = pr.id
		INNER JOIN dbCureSA.Medico m ON rt.idMedico = m.id
		INNER JOIN dbCureSA.Especialidad e ON rt.idEspecialidad = e.id
	WHERE et.estado = 'ATENDIDO' AND pr.nombre = @obraSocial AND rt.fecha BETWEEN @fechaInicio AND @fechaFin
	FOR XML PATH('Turnos'), TYPE;
END
GO

-- Procedures específicos al borrado 
-- Los siguientes STORE PROCEDURES no borraran el registro, si no que lo dejarán inactivo mediante el bit 0

CREATE OR ALTER PROCEDURE spCureSA.eliminarPaciente @dni AS VARCHAR(50)
AS
	SET NOCOUNT ON;

	DECLARE @ilog AS VARCHAR(250), @paciente AS VARCHAR(100);
	
	BEGIN TRY
		UPDATE dbCureSA.Paciente
		SET activo = 0
		WHERE nroDoc = @dni

		IF @@ROWCOUNT <> 1
			RAISERROR('No se ha encontrado el documento solicitado',16,1);

		SET @paciente = (SELECT Apellido + ', ' + Nombre FROM dbCureSa.Paciente);
		SET @ilog = '[dbCureSA.Paciente] - ' + @paciente + ' ; DNI: ' + @dni;
		
		PRINT 'Se ha eliminado el paciente:' + @paciente + '; DNI: ' + @dni 

		EXEC spCureSA.InsertarLog @texto = @ilog, @modulo = '[DELETE]'
		COMMIT TRAN
	END TRY
	BEGIN CATCH
		PRINT '[ERROR] - NO SE HA PODIDO BORRAR EL PACIENTE SOLICITADO'
        PRINT '[ERROR] - ' +'[LINE]: ' + CAST(ERROR_LINE() AS VARCHAR) + ' - [MSG]: ' + ERROR_MESSAGE()
		
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN

	END CATCH

	SET NOCOUNT OFF;
GO

CREATE OR ALTER PROCEDURE spCureSA.eliminarMedico @nroMatricula AS VARCHAR(50)
AS
	SET NOCOUNT ON;

	DECLARE @ilog AS VARCHAR(250), @medico AS VARCHAR(100);
	
	BEGIN TRY
		BEGIN TRANSACTION
		UPDATE dbCureSA.Medico
		SET activo = 0
		WHERE nroMatricula = @nroMatricula

		SET @medico = (SELECT Apellido + ', ' + Nombre FROM dbCureSa.Medico WHERE nroMatricula = @nroMatricula);
		SET @ilog = '[dbCureSA.Medico] - ' + @medico + ' ; Matricula: ' + @nroMatricula;
		
		PRINT 'Se ha eliminado el medico: ' + @medico + '; Matricula: ' + @nroMatricula 
		EXEC spCureSA.InsertarLog @texto = @ilog, @modulo = '[DELETE]'

		COMMIT TRAN
	END TRY
	BEGIN CATCH
		PRINT '[ERROR] - NO SE HA PODIDO BORRAR EL MEDICO SOLICITADO'
        PRINT '[ERROR] - ' +'[LINE]: ' + CAST(ERROR_LINE() AS VARCHAR) + ' - [MSG]: ' + ERROR_MESSAGE()

		IF @@TRANCOUNT > 0
			ROLLBACK TRAN

	END CATCH

	SET NOCOUNT OFF;
GO

-- Procedure "Alianza Comercial" para 'CANCELAR' todos los turnos que se encuentren asociados
-- a las prestadoras eliminadas
CREATE OR ALTER PROCEDURE spCureSA.alianzaComercial @prestador AS VARCHAR(50)
	, @fecha AS DATE
	, @hora AS TIME = '00:00:00'
AS
	SET NOCOUNT ON;

	DECLARE @ilog AS VARCHAR(250);
	
	-- Validar que la fecha ingresada no sea nula
	IF @fecha IS NULL
		SET @fecha = CAST(GETDATE() AS DATE);

	BEGIN TRY
		BEGIN TRANSACTION

		-- Cancelar los turnos reservados posteriores a la fecha actual
		UPDATE dbCureSA.ReservaTurno
		SET idEstado = (SELECT ID FROM dbCureSa.EstadoTurno WHERE UPPER(estado) = 'CANCELADO') 
		WHERE (fecha = @fecha AND hora >= @hora)
				OR (fecha >= @fecha)
		
		IF @@ROWCOUNT > 0
			BEGIN
			SET @ilog = '[dbCureSA.ReservaTurno] - Se cancelaron ' + CAST(@@ROWCOUNT AS VARCHAR) 
						+ 'turnos de ' + @prestador + ' (finalización Alianza Comercial), a partir de la fecha: '
						+ CAST(@fecha AS VARCHAR) + ' ' + CAST(@hora AS VARCHAR);
			END
		ELSE
			BEGIN
			SET @ilog = '[dbCureSA.ReservaTurno] - No se han cancelado turnos de ' + @prestador + ' (finalización Alianza Comercial), a partir de la fecha: '
						+ CAST(@fecha AS VARCHAR) + ' ' + CAST(@hora AS VARCHAR) + 'ya que no hay ningun turno asociado';
			END
		
		PRINT @ilog
		EXEC spCureSA.InsertarLog @texto = @ilog, @modulo = '[UPDATE]'

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		PRINT '[ERROR] - NO SE HA PODIDO BORRAR EL PRESTADOR SOLICITADO'
		PRINT '[ERROR] - ' +'[LINE]: ' + CAST(ERROR_LINE() AS VARCHAR) + ' - [MSG]: ' + ERROR_MESSAGE()
		
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN

	END CATCH
GO

CREATE OR ALTER PROCEDURE spCureSA.eliminarPrestador @prestador AS VARCHAR(50)
AS
	SET NOCOUNT OFF;

	DECLARE @ilog AS VARCHAR(250);
	DECLARE @fechaE AS DATE = CAST(GETDATE() AS DATE), @horaE AS TIME = CAST(GETDATE() AS TIME);

	BEGIN TRY
		BEGIN TRANSACTION

		-- Dar de baja Prestador logicamente al porestador pasado por parametro
		UPDATE dbCureSA.Prestador
		SET activo = 0
		WHERE nombre = @prestador

		IF @@ROWCOUNT < 1
			RAISERROR('No se ha encontrado prestadores para eliminar con el nombre solicitado',16,1);

		PRINT 'Se ha eliminado el prestador: ' + @prestador
		
		SET @ilog = '[dbCureSA.Prestador] - ' + @prestador;
		EXEC spCureSA.InsertarLog @texto = @ilog, @modulo = '[DELETE]'

		-- Incorporación AlianzaComercial, para cancelar todos los turnos a partir de la fecha actual
		EXEC spCureSA.alianzaComercial @prestador = @prestador, @fecha = @fechaE, @hora = @horaE

		COMMIT TRAN
	END TRY
	BEGIN CATCH
		PRINT '[ERROR] - NO SE HA PODIDO BORRAR EL PRESTADOR SOLICITADO'
		PRINT '[ERROR] - ' +'[LINE]: ' + CAST(ERROR_LINE() AS VARCHAR) + ' - [MSG]: ' + ERROR_MESSAGE()
		
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN

	END CATCH
	
	SET NOCOUNT ON;
GO

-- Procedure para automatizar la carga de estudios a modo de ejemplo.
-- será eliminado luego de la ejecución.

CREATE OR ALTER PROCEDURE spCureSA.crearEstudiosAleatorios @estudios INT
AS
	SET NOCOUNT ON;
	DECLARE @idMax as int, @idMin as int, @contador as int;
	DECLARE @aux TABLE (nombreEstudio VARCHAR(100)); 

	SELECT	@idMax = MAX(idHistoriaClinica)
		,	@idMin = MIN(idHistoriaClinica) 
	FROM dbCureSA.Paciente

	INSERT INTO @aux
	SELECT DISTINCT nombreEstudio
	FROM dbCureSA.Autorizacion

	SET @contador = @estudios;

	WHILE @contador > 0
	BEGIN
		INSERT INTO dbCureSA.Estudio (idPaciente, fecha, nombreEstudio)
		SELECT
				CAST(RAND()*(@idMax - @idMin) + @idMin AS int)				AS idPaciente
			,	DATEADD(DD, CAST(RAND()*(65 - 1) + 1 AS int), GETDATE())	AS fecha
			,	(SELECT TOP 1 nombreEstudio FROM @aux ORDER BY NEWID())		AS nombreEstudio

		SET @contador = @contador - 1;
	END

	SET NOCOUNT OFF;
GO

-- Procedure para automatizar la carga de COBERTURAS a modo de ejemplo.
-- será eliminado luego de la ejecución.

CREATE OR ALTER PROCEDURE [spCureSA].[generarCoberturas]
AS 
SET NOCOUNT ON;
declare @contador int
	,@limiteSuperior int
	,@limiteInferior int
	,@registrosAgenerar int
-- Inicializo valores y limites

set @contador = (SELECT TOP 1 idHistoriaClinica FROM dbCureSA.Paciente ORDER BY 1 ASC);
set @limiteInferior = 1
set @limiteSuperior = 1000000
set @registrosAgenerar = (SELECT TOP 1 idHistoriaClinica FROM dbCureSA.Paciente ORDER BY 1 DESC);
while @contador < @registrosAgenerar
	begin	
		insert INTO dbCureSA.Cobertura(nroSocio, idPrestador, fechaRegistro,idPaciente)
			select 
				Cast(RAND()*(@limiteSuperior-@limiteInferior)+@limiteInferior as int),
				Cast(RAND()*(21-1)+1 as int),
				GETDATE(),
				@contador + 1
		set @contador = @contador + 1
	end
SET NOCOUNT OFF;
GO

-- Procedure para automatizar la carga de Turnos a modo de ejemplo.
CREATE OR ALTER PROCEDURE spCureSA.InsertarReservaTurno @cantidad INT
AS
	SET NOCOUNT ON;

	DECLARE @ilog AS VARCHAR(250);
	
	DECLARE @fechaInicio DATE = '2023-01-01', @fechaFin DATE = GETDATE();

	DECLARE @minDiaSede AS INT, @maxDiaSede AS INT;
	DECLARE @minPaciente AS INT, @maxPaciente AS INT;
	DECLARE @minEstado AS INT, @maxEstado AS INT;
	DECLARE @minTipo AS INT, @maxTipo AS INT;
	DECLARE @minMedico AS INT, @maxMedico AS INT;
	DECLARE @minSede AS INT, @maxSede AS INT;
	DECLARE @minEspecialidad AS INT, @maxEspecialidad AS INT;

	DECLARE @contador AS INT = 0;

	BEGIN TRY
		BEGIN TRANSACTION
			SELECT @minDiaSede = MIN(id), @maxDiaSede = MAX(id)
			FROM dbCureSA.DiasXSede

			SELECT @minPaciente = MIN(idHistoriaClinica), @maxPaciente = MAX(idHistoriaClinica)
			FROM dbCureSA.Paciente

			SELECT @minEstado = MIN(id), @maxEstado = MAX(id)
			FROM dbCureSA.EstadoTurno

			SELECT @minTipo = MIN(id), @maxTipo = MAX(id)
			FROM dbCureSA.TipoTurno

			SELECT @minMedico = MIN(id), @maxMedico = MAX(id)
			FROM dbCureSA.Medico
		
			SELECT @minSede = MIN(id), @maxSede = MAX(id)
			FROM dbCureSA.Sede

			SELECT @minEspecialidad = MIN(id), @maxEspecialidad = MAX(id)
			FROM dbCureSA.Especialidad

			WHILE @contador < @cantidad
			BEGIN
				INSERT INTO dbCureSA.ReservaTurno(fecha, hora, idDiaSede, idPaciente, idEstado, idTipo, idMedico, idEspecialidad, idSede)
				SELECT	DATEADD(DAY, ABS(CHECKSUM(NEWID())) % (DATEDIFF(DAY, @fechaInicio, @fechaFin) + 1), @fechaInicio) AS fecha
						,CONVERT(TIME, DATEADD(SECOND, RAND() * 86400, '00:00:00'))		AS hora
						,CAST(RAND() * (@maxDiaSede - @minDiaSede) + @minDiaSede AS INT)	AS idDiaSede
						,CAST(RAND() * (@maxPaciente - @minPaciente) + @minPaciente AS INT)	AS idPaciente
						,CAST(RAND() * (@maxEstado - @minEstado) + @minEstado AS INT)	AS idEstado
						,CAST(RAND() * (@maxTipo - @minTipo) + @minTipo AS INT)	AS idTipo
						,CAST(RAND() * (@maxMedico - @minMedico) + @minMedico AS INT)	AS idMedico
						,CAST(RAND() * (@maxEspecialidad - @minEspecialidad) + @minEspecialidad AS INT)	AS idEspecialidad
						,CAST(RAND() * (@maxSede - @minSede) + @minSede AS INT)			AS idSede

				SET @contador = @contador + 1;
			END

			SET @ilog = '[dbCureSA.ReservaTurno] - ' + CAST(@@ROWCOUNT AS varchar) + ' registros nuevos';
		
			EXEC spCureSA.InsertarLog @texto = @ilog, @modulo = '[INSERT]'
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		PRINT '[ERROR] - NO SE HA PODIDO INSERTAR RESERVAS EN LOS TURNOS'
		PRINT '[ERROR] - ' + '[LINE]: ' + ERROR_LINE() + ' - [MSG]: ' + ERROR_MESSAGE()
		
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION

	END CATCH
	SET NOCOUNT OFF;
GO

-- Procedure para automatizar la carga de diasxsede a modo de ejemplo.
CREATE OR ALTER PROCEDURE spCureSA.InsertarDiasXSede @cantidad INT
AS
	SET NOCOUNT ON;

	DECLARE @ilog AS VARCHAR(250);
	DECLARE @fechaInicio DATE = '2023-01-01';
	DECLARE @fechaFin DATE = GETDATE();
	DECLARE @minSede AS INT, @maxSede AS INT;
	DECLARE @minMedico AS INT, @maxMedico AS INT;
	DECLARE @contador AS INT = 0;

	BEGIN TRY
		BEGIN TRANSACTION
			SELECT @minSede = MIN(id), @maxSede = MAX(id)
			FROM dbCureSA.Sede

			SELECT @minMedico = MIN(id), @maxMedico = MAX(id)
			FROM dbCureSA.Medico

			WHILE @contador < @cantidad
			BEGIN
				INSERT INTO dbCureSA.DiasXSede(idSede, idMedico, dia, horaInicio)
				SELECT	CAST(RAND() * (@maxSede - @minSede) + @minSede AS INT)			AS idSede
						,CAST(RAND() * (@maxMedico - @minMedico) + @minMedico AS INT)	AS idMedico
						,DATEADD(DAY, ABS(CHECKSUM(NEWID())) % (DATEDIFF(DAY, @fechaInicio, @fechaFin) + 1), @fechaInicio) AS dia
						,CONVERT(TIME, DATEADD(SECOND, RAND() * 86400, '00:00:00'))		AS horaInicio

				SET @contador = @contador + 1;
			END

			SET @ilog = '[dbCureSA.DiasXSede] - ' + CAST(@@ROWCOUNT AS varchar) + ' registros nuevos';
		
			EXEC spCureSA.InsertarLog @texto = @ilog, @modulo = '[INSERT]'
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		PRINT '[ERROR] - NO SE HA PODIDO INSERTAR NUEVOS DIAS POR SEDE'
		PRINT '[ERROR] - ' + '[LINE]: ' + ERROR_LINE() + ' - [MSG]: ' + ERROR_MESSAGE()
		
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION

	END CATCH
	SET NOCOUNT OFF;
GO

-- CREACION DE TRIGGERS
-- =====================================
-- Se encuentra disponible para incorporar los estudios que sean autorizados o no.
-- en caso de no existir el nombre de estudio con el centro de autorizaciones, el estudio no se cargará.
GO
CREATE OR ALTER TRIGGER autorizarEstudio ON dbCureSA.Estudio
INSTEAD OF INSERT
AS 	
	-- Autorizar turnos segun las características la cobertura del paciente
	INSERT INTO dbCureSA.Estudio (idPaciente, nombreEstudio, fecha, autorizado, costo)
	SELECT 	i.idPaciente	-- ID Historia Clinica Paciente
		,	i.nombreEstudio
		,	i.fecha			
		,	a.autorizacion	-- autorizado
		,	a.costo * (1 - a.porcCobertura)
	FROM inserted i
	JOIN dbCureSA.Cobertura c ON i.idPaciente = c.idPaciente
	JOIN dbCureSA.Autorizacion a ON c.idPrestador = a.idPrestador AND i.nombreEstudio = a.nombreEstudio

GO

-- CREACIÓN DE ROLES
-- =====================================
GO
IF EXISTS (SELECT 1 from sys.database_principals WHERE name = 'paciente' AND type = 'R')
	DROP ROLE paciente

CREATE ROLE paciente
GO

IF EXISTS (SELECT 1 from sys.database_principals WHERE name = 'medico' AND type = 'R')
	DROP ROLE medico

CREATE ROLE medico
GO

IF EXISTS (SELECT 1 from sys.database_principals WHERE name = 'personalAdministrativo' AND type = 'R')
	DROP ROLE personalAdministrativo

CREATE ROLE personalAdministrativo
GO

IF EXISTS (SELECT 1 from sys.database_principals WHERE name = 'personalTecnicoClinico' AND type = 'R')
	DROP ROLE personalTecnicoClinico

CREATE ROLE personalTecnicoClinico
GO

IF EXISTS (SELECT 1 from sys.database_principals WHERE name = 'administradorGeneral' AND type = 'R')
	DROP ROLE administradorGeneral

CREATE ROLE administradorGeneral
	
-- CARGA DE DATOS INICIALES
-- =====================================

BEGIN TRY
	BEGIN TRANSACTION
	
	SET NOCOUNT ON;
	DECLARE @RUTA				VARCHAR(100) = 'C:\importar\';
	DECLARE @rutasede 			VARCHAR(300) = @RUTA + 'Sedes.csv';
	DECLARE @rutamedico 		VARCHAR(300) = @RUTA + 'Medicos.csv';
	DECLARE @rutaprestador 		VARCHAR(300) = @RUTA + 'Prestador.csv';
	DECLARE @rutapaciente 		VARCHAR(300) = @RUTA + 'Pacientes.csv';
	DECLARE @rutaautorizacion	VARCHAR(300) = @RUTA + 'Centro_Autorizaciones.Estudios clinicos.json';
	
	INSERT INTO dbCureSA.EstadoTurno (estado) VALUES ('Atendido'), ('Ausente'), 
		('Cancelado'), ('Pendiente'); 
	INSERT INTO dbCureSA.TipoTurno (tipo) VALUES ('Presencial'), ('Virtual');
	
	EXEC spCureSA.insertarMasivoSede @rutacsv = @rutasede;
	EXEC spCureSA.insertarMasivoEspecialidad @rutacsv = @rutamedico;
	EXEC spCureSA.insertarMasivoMedico @rutacsv = @rutamedico;
	EXEC spCureSA.insertarMasivoPrestador @rutacsv = @rutaprestador;
	EXEC spCureSA.insertarMasivoPaciente @rutacsv = @rutapaciente;
	EXEC spCureSA.insertarMasivoDomicilio @rutacsv = @rutapaciente;
	EXEC spCureSA.insertarMasivoAutorizacion @rutajson = @rutaautorizacion;
	EXEC spCureSA.insertarMasivoUsuario
	
	EXEC spCureSA.generarCoberturas;
	EXEC spCureSA.crearEstudiosAleatorios 500;
	EXEC spCureSA.InsertarDiasXSede 50;
	EXEC spCureSA.InsertarReservaTurno 1000;

	DROP PROCEDURE spCureSA.crearEstudiosAleatorios;
	
	PRINT 'Carga de datos inicial COMPLETA'
	
	COMMIT TRANSACTION
END TRY
BEGIN CATCH
	PRINT '[ERROR] - NO SE HA PODIDO IMPORTAR SATISFACTORIAMENTE UNO DE LOS ARCHIVOS'
	PRINT '[ERROR] - ' +'[LINE]: ' + CAST(ERROR_LINE() AS VARCHAR) + ' - [MSG]: ' + ERROR_MESSAGE()
	
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION

END CATCH

SET NOCOUNT OFF;