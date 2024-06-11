--================================================================================================================
/*
	************************************
    * Materia : Base de Datos Aplicada *
	* Curso y Comision: 02-5600		   *
	* Fecha de Entrega: 14/06		   *
	* Numero Grupo: 8				   *
	************************************
	Alumno/as:
		De Jesús, Rocio		  - 44.726.983
		Gliwa, Lucas		  - 43.915.507
		Masino, Nicolás		  - 42.855.529
		Rivas, Nahuel Alberto - 44.364.975
*/

-- ===============================================================================================================
--creaamos la base de datos con el nombre en criterio al enunciado "generar una db con nombre "COMXXXXGYY" 
--donde XXXX hace referencia al numero de comision y YY hace referencia al nro del grupo
IF  NOT EXISTS(SELECT 1 FROM SYS.DATABASES WHERE NAME = 'COM5600G08')
	CREATE DATABASE COM5600G08;
GO
USE COM5600G08
GO
set nocount on
GO
--creacion de esquema para la creación de la db
IF NOT EXISTS(SELECT 1 FROM SYS.schemas WHERE name LIKE 'dbHospital')
	 EXEC('CREATE SCHEMA dbHospital;');
GO
-- creación de esquema para los sp
IF NOT EXISTS(SELECT 1 FROM SYS.schemas WHERE name LIKE 'spHospital')
	 EXEC('CREATE SCHEMA spHospital;');
GO
-- creación de esquema para las funciones
IF NOT EXISTS(SELECT 1 FROM SYS.schemas WHERE name LIKE 'fnHospital')
	 EXEC('CREATE SCHEMA fnHospital;');
GO
-- creación de esquema para los log
IF NOT EXISTS(SELECT 1 FROM SYS.schemas WHERE name LIKE 'logHospital')
	 EXEC('CREATE SCHEMA logHospital;');
GO



--**********CREACION DE TABLAS***********

--los nombres de las tablas son el singular --no es 'pacientes' es 'paciente'
--tabla paciente

-- sys.tables, proporciona información específica sobre todas las tablas de usuario en la base de datos actual.
-- SYS.all_objects,contiene información sobre todos los objetos en la base de datos : vistas, sp, tablas, funciones, trigges
--dependiendo de la necesita de información que requerimos, una vista puede ser mas útil que la otra, en este caso, sería más óptimo utilizar sys.tables, en contexto de performance.

--- tabla paciente

-- otra forma de consultar si existe la tabla 

IF NOT EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'paciente'   AND schema_id = SCHEMA_ID('dbHospital')) 
BEGIN
	CREATE TABLE dbHospital.paciente(

		id_historia_clinica		int  identity(1,1) PRIMARY KEY, -- ponemos identity?-charlarlo con el grupo-
		nombre					varchar(30) NOT NULL,
		apellido				varchar(30) NOT NULL,
		apellidoMaterno			varchar(30) NOT NULL,
		fechaNacimiento			datetime NOT NULL, -- consultar con el grupo
		tipoDoc					varchar(10) NOT NULL,
		numDoc					char(8) NOT NULL,
		sexoBio					char NOT NULL,
		genero					varchar(20) NOT NULL,
		nacionalidad			varchar (20) NOT NULL,
		fotoPerfil				varchar (50) NOT NULL,
		mail					varchar(50) UNIQUE NOT NULL,
		telFijo				    varchar(14) NOT NULL,
		telAlt					varchar(14),
		telLaboral				varchar(14),
		fechaRegistro			date NOT NULL,
		fechaAct				date NOT NULL,
		usuarioAct				varchar(40),
		CONSTRAINT CK_mail CHECK (
			mail LIKE '%@%'							-- Debe contener al menos un símbolo "@".
			AND mail LIKE '%.%'						-- Debe contener al menos un punto ".".
			AND mail NOT LIKE '%@%@%'				-- Debe tener solo un símbolo "@".
			AND LEN(mail) > 5						-- Debe tener al menos 5 caracteres.
			AND LEN(mail) < 30						-- Debe tener hasta 30 caracteres.
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
			--OR telAlt IS NULL						--Puede ser NULL-> no es extrictamente necesario, ya se especifíco al momento de crear el campo	
		),
		CONSTRAINT CK_telLaboral CHECK((
			LEN(telLaboral) >= 10					-- Debe tener al menos 10 caracteres.
			AND LEN(telLaboral) <= 13				-- Debe tener como máximo 13 caracteres.
			--AND ISNUMERIC(telLaboral) = 1			-- Debe ser numérico.
			AND telLaboral NOT LIKE '%[^(0-9)\-]%')	-- Debe contener solo dígitos numéricos.
			--OR telLaboral IS NULL					-- Puede ser NULL ->no es extrictamente necesario, ya se especifíco al momento de crear el campo					
		),
		CONSTRAINT CK_sexoBio CHECK(
			sexoBio IN ('F','M')					-- Debe ser 'Femenino' o 'Masculino'
		),
		CONSTRAINT CK_nroDoc CHECK (
			numDoc NOT LIKE '[^0-9]'				-- Debe ser unicamente dígitos. " [^0-9] " -> 'no puede ser distinto a numerico' 
			AND LEN(numDoc) >= 7					-- Debe tener una longitud mayor o igual a dígitos.
		)
	);
END


GO -- NO OLVIDARSE EL GO

--******************************************************************************************

--tabla estudio

 
IF NOT EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'estudio'   AND schema_id = SCHEMA_ID('dbHospital')) 
BEGIN
		CREATE TABLE dbHospital.estudio(
			id_estudio			int PRIMARY KEY,
			fecha				datetime NOT NULL,
			nombreEstudio		varchar(80) NOT NULL,
			autorizado			BIT DEFAULT 0, -- tipo de dato BIT- > dato bool,0 =false, 1= true , el contexto -> 0= no autorizado, 1= autorizado 
			docResultado		varchar(100) NOT NULL,
			imagenResultado	    varchar(100) NOT NULL,
			id_hist_clinica		int,
			CONSTRAINT fk_estudioPaciente FOREIGN KEY (id_hist_clinica) REFERENCES dbHospital.paciente(id_historia_clinica)
		);
END
GO

--******************************************************************************************

--tabla usuario

-- FUNCION de tipo ESCALAR, valida/verifica que el DNI ingresado en la tabla usuario, exista (y sea el mismo) en la tabla paciente.

CREATE OR ALTER FUNCTION fnHospital.verificacionDocPaciente(@dni CHAR(8))
RETURNS BIT
AS
   BEGIN
		DECLARE @dniPaciente CHAR(8) = 'datorand'; -- inicializamos la variable dniPaciente con una cadena, primero para que no tome datos basura, 
													--segundo, para que sepamos con certeza que si no existe el documento en la tabla paciente, la comparación efectivamente va a ser falsa
		SELECT @dniPaciente = numDoc FROM dbHospital.paciente WHERE numDoc = @dni
		IF(@dniPaciente <> @dni)
			RETURN 0

		RETURN 1
	END
GO	

IF NOT EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'usuario' AND schema_id = SCHEMA_ID('dbHospital')) 
BEGIN		
	

	-- usuario es DEBIL de PACIENTE, ya que no existiria un usuario sin la existencia de un paciente.
	CREATE TABLE dbHospital.usuario(
		id_usuario_paciente		int,
		id_doc_paciente			char(8), --> DNI , debe coincidir con el documento, para eso la funcion de arriba
		contrasenia				varchar(40) NOT NULL,
		fechaCreacion			date NOT NULL,
	
		CONSTRAINT pk_usuario PRIMARY KEY (id_usuario_paciente,id_doc_paciente),
		CONSTRAINT fk_usuarioPaciente FOREIGN KEY (id_usuario_paciente) REFERENCES dbHospital.paciente(id_historia_clinica),

		CONSTRAINT ck_contraseniaUsu CHECK (
			LEN(contrasenia) >= 8								-- Longitud mínima de 8 caracteres
			AND CHARINDEX(UPPER(contrasenia), contrasenia) > 0	-- Al menos una letra mayúscula
			AND CHARINDEX(LOWER(contrasenia), contrasenia) > 0	-- Al menos una letra minúscula
			AND PATINDEX('%[0-9]%', contrasenia) > 0			-- Al menos un número
		),
		CONSTRAINT ck_idPaciente CHECK (
			id_doc_paciente NOT LIKE '[^0-9]' --es necesario este check, existiendo la funcion?
			AND LEN(id_doc_paciente) >= 7
			AND fnHospital.verificacionDocPaciente(id_doc_paciente) = 1 --aca llamamos a la funcion para verificar que exista y coincidencia del DNI de la tabla PACIENTE, entonces se valida la cuenta usuario
		)
	);
END
GO

--******************************************************************************************

--tabla domicilio
IF NOT EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'domicilio' AND schema_id = SCHEMA_ID('dbHospital')) 
BEGIN


	CREATE TABLE dbHospital.domicilio(
		id_domicilio		int IDENTITY (1,1) PRIMARY KEY ,--y si ponemos identity
		calle				varchar(30) NOT NULL,
		numero				int NOT NULL,
		piso				int,
		departamento		int,
		codigoPostal		int NOT NULL,
		pais				varchar(20) NOT NULL,
		provincia			varchar(30) NOT NULL,
		localidad			varchar(30)  NOT NULL,
		id_hist_clinica		int,
		CONSTRAINT fk_domicilioPaciente FOREIGN KEY (id_hist_clinica) REFERENCES dbHospital.paciente(id_historia_clinica),
		CONSTRAINT ck_cpDomicilio CHECK (LEN(codigoPostal) = 4 )
	);
END
GO

--******************************************************************************************

--tabla cobertura

IF NOT EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'cobertura' AND schema_id = SCHEMA_ID('dbHospital')) 
BEGIN
	CREATE TABLE dbHospital.cobertura(
		id_cobertura		int PRIMARY KEY, -- vamo a poner un codigo de 7 digitos, asi sacamos el identity un poco
		imagenCredencial	varchar(80) NOT NULL, -- como planteamos la imagen? es un link?
		nroSocio			int NOT NULL,
		fechaRegistro		date NOT NULL, --es necesario?
		id_hist_clinica		int,
		CONSTRAINT fk_coberturaPaciente FOREIGN KEY (id_hist_clinica) REFERENCES dbHospital.paciente(id_historia_clinica),
		CONSTRAINT ck_idCobertura CHECK ( LEN (id_cobertura) = 7) --podemos sacarlo tranqui
	);
END
GO
--******************************************************************************************

--tabla prestador

IF NOT EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'prestador' AND schema_id = SCHEMA_ID('dbHospital')) 
BEGIN

	CREATE TABLE dbHospital.prestador (
		id_prestador		int PRIMARY KEY,
		nombrePrestador		varchar(50) UNIQUE NOT NULL,
		planPrestador		varchar(50) NOT NULL,
		activo				bit default 1,
		id_cobertura		int,
		CONSTRAINT fk_prestadorCobertura FOREIGN KEY (id_cobertura) REFERENCES dbHospital.cobertura (id_cobertura),
		CONSTRAINT ck_idPrestador CHECK (LEN (id_prestador) = 3)
	);
END
GO

--******************************************************************************************

--tabla estado de turno
IF NOT EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'estadoTurno' AND schema_id = SCHEMA_ID('dbHospital')) 
BEGIN
	CREATE TABLE dbHospital.estadoTurno(
		id_estado_turno		int PRIMARY KEY,
		estado	varchar(20) NOT NULL,

		CONSTRAINT CK_estadoTurno CHECK(
			UPPER(estado) = 'ATENDIDO'
			OR UPPER(estado) = 'AUSENTE'
			OR UPPER(estado) = 'CANCELADO'
		)
	);
END
GO
--******************************************************************************************

--tabla tipo de turno
IF NOT EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'tipoTurno' AND schema_id = SCHEMA_ID('dbHospital')) 
BEGIN
	CREATE TABLE dbHospital.tipoTurno(--no se si las campos estan bien
		id_tipo_turno		int PRIMARY KEY,
		tipoTurno		varchar(10) NOT NULL,

		CONSTRAINT CK_tipoTurno CHECK(
			UPPER(tipoTurno) = 'PRESENCIAL'
			OR UPPER(tipoTurno) = 'VIRTUAL'
		)
	);
END
go

--*******************************************************************************************

-- tabla sede de atencion
IF NOT EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'sedeDeAtencion' AND schema_id = SCHEMA_ID('dbHospital')) 
BEGIN
	CREATE TABLE dbHospital.sedeDeAtencion(
		id_sede			 int PRIMARY KEY,
		nombreDeSede	 varchar(30) NOT NULL,
		direccionSede	 varchar(50) NOT NULL
	);
END
GO

--******************************************************************************************

-- tabla especialidad
IF NOT EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'especialidad' AND schema_id = SCHEMA_ID('dbHospital')) 
BEGIN

	CREATE TABLE dbHospital.especialidad(
		id_especialidad			int PRIMARY KEY, --usamos alguna constraint mas? que criterio tienen los id de especialidad?
		nombreEspecialidad		varchar(40),

		CONSTRAINT ck_idEspecialidad CHECK ( LEN(id_especialidad) = 5) --decidimos que, el id debe tener 5 digitos (esto podemos borrarlo)
	);
END	
GO

--******************************************************************************************

-- tabla medico
IF NOT EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'medico' AND schema_id = SCHEMA_ID('dbHospital')) 
BEGIN
	CREATE TABLE dbHospital.medico(
		id_medico				 int PRIMARY KEY,-- -usamos alguna constraint mas? que criterio tienen los id de especialidad? charlarlo con el grupo
		nombre					 varchar(30) NOT NULL,
		apellido				 varchar(30) NOT NULL,
		nroMatricula			 int NOT NULL,
		id_especialidad_medico	 int,
		CONSTRAINT fk_medicoEspecialidad FOREIGN KEY (id_especialidad_medico) REFERENCES dbHospital.especialidad (id_especialidad),
		CONSTRAINT ck_idMedico CHECK (LEN(id_medico) = 3) --podemos borrarlo
	);
END
GO

--******************************************************************************************

--tabla dias x sede
IF NOT EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'diasXsede' AND schema_id = SCHEMA_ID('dbHospital')) 
BEGIN
	CREATE TABLE dbHospital.diasXsede(
		id_dia_sede			int PRIMARY KEY,--que criterio tienen los ID de las sede?
		dia				varchar(10) NOT NULL, 
		horaInicio		varchar(10) NOT NULL, 
		id_medico	    int,
		id_sede_atencion int,
		CONSTRAINT fk_diasXsedeMedico FOREIGN KEY (id_medico) REFERENCES dbHospital.medico (id_medico),
		CONSTRAINT fk_diasXsedeSedeAtencion FOREIGN KEY (id_sede_atencion) REFERENCES dbHospital.sedeDeAtencion (id_sede),
		CONSTRAINT UQ_diasSede UNIQUE (id_dia_sede, id_medico, dia, horaInicio) -- para un mismo dia, misma sede, mismo medico y misma hora solo existe 1 turno, por ende debe ser unico
	);
END
GO

--******************************************************************************************

--tabla reserva de turno medico
IF NOT EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'reservaTurnoMedico' AND schema_id = SCHEMA_ID('dbHospital')) 
BEGIN
	CREATE TABLE dbHospital.reservaTurnoMedico(
		id_reserva_turno	int identity(1,1) PRIMARY KEY,
		fecha				date NOT NULL,
		hora				time NOT NULL,
		id_diaSede			int,
		id_paciente			int,
		id_estado			int,
		id_tipoTurno		int,
		id_medico			int,
		id_especialidad		int,
		id_sedeAten			int,
	
		CONSTRAINT FK_reservaDiasxSede FOREIGN KEY (id_diaSede) REFERENCES dbHospital.diasXsede (id_dia_sede),
		CONSTRAINT FK_reservaPaciente FOREIGN KEY (id_paciente) REFERENCES dbHospital.paciente (id_historia_clinica),
		CONSTRAINT FK_reservaEstadoTurno FOREIGN KEY (id_estado) REFERENCES dbHospital.estadoTurno (id_estado_turno),
		CONSTRAINT FK_reservaTipoTurno FOREIGN KEY (id_tipoTurno) REFERENCES dbHospital.tipoTurno(id_tipo_turno),
		CONSTRAINT FK_reservaMedico FOREIGN KEY (id_medico) REFERENCES dbHospital.medico (id_medico),
		CONSTRAINT FK_reservaEspecialidadMed FOREIGN KEY (id_especialidad) REFERENCES dbHospital.especialidad (id_especialidad),
		CONSTRAINT FK_reservaSede FOREIGN KEY (id_sedeAten) REFERENCES dbHospital.sedeDeAtencion (id_sede)
	);
END
GO

--***********************************************************************************************************


-- ***************************** STORE PROCEDURES **************************


-- ***************************** INSERCION DE DATOS **************************
CREATE OR ALTER PROCEDURE spHospital.insercionDatos(
		@nombreEsquema NVARCHAR(128),   -- Nombre del esquema /PUEDE SER OPCIONAL, DEPENDIENDO DE LA FORMA QUE TOMEMOS
		@nombreTabla NVARCHAR(128),  -- Variable que contendra el nombre de la tabla a insertar
		@campos NVARCHAR(MAX),    -- Variable que contiene los nombres de los campos a ingresar datos
		@valores NVARCHAR(MAX)  -- Variable que contiene la lista de valores
		)
		AS    
	BEGIN
		-- Inicio de la sección TRY para manejo de errores
		BEGIN TRY
			-- Declaración de una variable para almacenar la consulta SQL dinámica
		
			DECLARE @sql NVARCHAR(MAX);

			-- Construcción de la consulta de inserción utilizando SQL dinámico
			--forma 1, con el esquema  pasado como parametro
			SET @sql = N'INSERT INTO '+ QUOTENAME(@nombreEsquema)+'.'+QUOTENAME(@nombreTabla)+
			'(' + @campos + ') VALUES (' + @valores + ');';
			--segunda forma
			 --SET @sql = N'INSERT INTO dbHospital.'+ QUOTENAME(@nombreTabla) + N'(' + @campos + ')' + N'VALUES' + '(' + @valores + ');';
	

			-- Ejecución de la consulta SQL dinámica
			EXEC sp_executesql @sql; --  sp_executesql permite ejecutar SQL dinámico con seguridad, especialmente cuando se pasan parámetros.
		END TRY
			-- Inicio de la sección CATCH para manejo de errores
		BEGIN CATCH
			-- Declaración de variables para capturar el mensaje y detalles del error
			DECLARE @mensajeError NVARCHAR(4000);
			DECLARE @gravedadDelError INT;
			DECLARE @estadoDelError INT;

			-- Obtención de los detalles del error ocurrido
			SELECT @mensajeError = ERROR_MESSAGE(),
				   @gravedadDelError = ERROR_SEVERITY(),
				   @estadoDelError = ERROR_STATE();
			-- Lanzamiento del error capturado para informar del fallo
			RAISERROR (@mensajeError, @gravedadDelError, @estadoDelError);
		END CATCH;
	END
GO

-- ***************************** MODIFICADO DE DATOS **************************

CREATE OR ALTER PROCEDURE spHospital.modificacionDatos(
    @nombreEsquema NVARCHAR(128), -- Nombre del esquema 
    @nombreTabla NVARCHAR(128),-- Variable que contendra el nombre de la tabla a modificar
    @clausulaSet NVARCHAR(MAX), -- Variable que contiene el contenido de la clausula set
    @clausulaWhere NVARCHAR(MAX)-- Variable que contiene el contenido de la clausula where
	) 
	AS
BEGIN
    BEGIN TRY
        DECLARE @sql NVARCHAR(MAX);

        -- Construcción de la consulta de actualización utilizando SQL dinámico
        SET @sql = N'UPDATE ' + QUOTENAME(@nombreEsquema) + '.' + QUOTENAME(@nombreTabla) +
                   N' SET ' + @clausulaSet +
                   N' WHERE ' + @clausulaWhere + ';';

        -- Ejecución de la consulta SQL dinámica
        EXEC sp_executesql @sql;
    END TRY
    BEGIN CATCH
        -- Manejo de errores
        DECLARE @mensajeError NVARCHAR(4000);
        DECLARE @gravedadDeError INT;
        DECLARE @estadoDelError INT;

        SELECT @mensajeError = ERROR_MESSAGE(),
               @gravedadDeError = ERROR_SEVERITY(),
               @estadoDelError = ERROR_STATE();

        -- Lanzar el error
        RAISERROR (@mensajeError, @gravedadDeError, @estadoDelError);
    END CATCH;
END
GO

-- ***************************** ELIMINACION DE DATOS **************************
CREATE OR ALTER PROCEDURE spHospital.borrarDatos(
    @nombreEsquema NVARCHAR(128),  -- Nombre del esquema
    @nombreTabla NVARCHAR(128),   -- Nombre de la tabla
    @clausuraWhere NVARCHAR(MAX)  -- Condición para la eliminación
	)
	AS
BEGIN
    BEGIN TRY
        DECLARE @sql NVARCHAR(MAX);

        -- Construcción de la consulta de eliminación utilizando SQL dinámico
        SET @sql = N'DELETE FROM ' + QUOTENAME(@nombreEsquema) + N'.' + QUOTENAME(@nombreTabla) +
                   N' WHERE ' + @clausuraWhere + N';';

        -- Ejecución de la consulta SQL dinámica
        EXEC sp_executesql @sql;
    END TRY
    BEGIN CATCH
        -- Manejo de errores
        DECLARE @mensajeError NVARCHAR(4000);
        DECLARE @gravedadDeError INT;
        DECLARE @estadoDelError INT;

        SELECT @mensajeError = ERROR_MESSAGE(),
               @gravedadDeError = ERROR_SEVERITY(),
               @estadoDelError = ERROR_STATE();

        -- Lanzar el error
        RAISERROR (@mensajeError, @gravedadDeError, @estadoDelError);
    END CATCH;
END
GO
