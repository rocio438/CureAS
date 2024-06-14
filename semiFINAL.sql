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

IF NOT EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'paciente' AND schema_id = SCHEMA_ID('dbHospital')) 
BEGIN
	CREATE TABLE dbHospital.paciente(

		id_historia_clinica		int  IDENTITY (1,1) PRIMARY KEY, -- ponemos identity?-charlarlo con el grupo-
		nombre					varchar(30) NOT NULL,
		apellido				varchar(30) NOT NULL,
		apellidoMaterno			varchar(30), --no viene en arhivo, puede ser null
		fechaNacimiento			date NOT NULL, -- 
		tipoDoc					varchar(10) NOT NULL,
		numDoc					char(8) NOT NULL,
		sexoBio					varchar(9) NOT NULL,
		genero					varchar(20) NOT NULL,
		nacionalidad			varchar (20) NOT NULL,
		fotoPerfil				varchar (50), --no viene en carga masiva, puede ser null
		mail					varchar(50) UNIQUE NOT NULL,
		telFijo				    varchar(14) NOT NULL,
		telAlt					varchar(14),
		telLaboral				varchar(14),
		fechaRegistro			datetime DEFAULT GETDATE(),
		fechaAct				datetime DEFAULT GETDATE(), 
		usuarioAct				varchar(40),
		CONSTRAINT ck_mail CHECK (
			mail LIKE '%@%'							-- Debe contener al menos un símbolo "@".
			AND mail LIKE '%.%'						-- Debe contener al menos un punto ".".
			AND mail NOT LIKE '%@%@%'				-- Debe tener solo un símbolo "@".
			AND LEN(mail) > 5						-- Debe tener al menos 5 caracteres.
			AND LEN(mail) < 30						-- Debe tener hasta 30 caracteres.
		),
		CONSTRAINT ck_telFijo CHECK(
			LEN(telFijo) >= 10						-- Debe tener al menos 10 caracteres.
			AND LEN(telFijo) <= 13					-- Debe tener como máximo 13 caracteres.
			--AND ISNUMERIC(telFijo) = 1			-- Debe ser numérico.
			AND telFijo NOT LIKE '%[^(0-9)\-]%'		-- Debe contener solo dígitos numéricos.
		),   --los datos de telfijo vienen cargados como (xxx) xxx-xxxx
		CONSTRAINT ck_telAlt CHECK((
			LEN(telAlt) >= 10						-- Debe tener al menos 10 caracteres.
			AND LEN(telAlt) <= 14					-- Debe tener como máximo 13 caracteres.
			--AND ISNUMERIC(telAlt) = 1				-- Debe ser numérico.
			AND telAlt NOT LIKE '%[^(0-9)\-]%')		-- Debe contener solo dígitos numéricos.
			--OR telAlt IS NULL						--Puede ser NULL-> no es extrictamente necesario, ya se especifíco al momento de crear el campo	
		),
		CONSTRAINT ck_telLaboral CHECK((
			LEN(telLaboral) >= 10					-- Debe tener al menos 10 caracteres.
			AND LEN(telLaboral) <= 13				-- Debe tener como máximo 13 caracteres.
			--AND ISNUMERIC(telLaboral) = 1			-- Debe ser numérico.
			AND telLaboral NOT LIKE '%[^(0-9)\-]%')	-- Debe contener solo dígitos numéricos.
			--OR telLaboral IS NULL					-- Puede ser NULL ->no es extrictamente necesario, ya se especifíco al momento de crear el campo					
		),
		CONSTRAINT ck_sexoBio CHECK(
			sexoBio IN ('Femenino','Masculino')			-- Debe ser 'Femenino' o 'Masculino'
		), --en archivo vienen como Femenino-masculino, no solo una letra
		CONSTRAINT ck_nroDoc CHECK (
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
			autorizado			bit DEFAULT 0, -- tipo de dato BIT- > dato bool,0 =false, 1= true , el contexto -> 0= no autorizado, 1= autorizado 
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
		id_domicilio		int IDENTITY (1,1) PRIMARY KEY ,--carga masiva no viene con identificador, le ponemos identity
		calle				varchar(30) NOT NULL,
		numero				int NOT NULL,
		piso				int,
		departamento		int,
		codigoPostal		int, --no viene en carga masiva, podria ser null
		pais				varchar(20), --no viene en carga masiva, podria ser null
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
		imagenCredencial	varchar(80) NOT NULL, 
		nroSocio			int NOT NULL,
		fechaRegistro		date NOT NULL, 
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
		id_prestador		varchar (50) PRIMARY KEY, --no viene en carga masiva, podria ser identity? - exacto
		nombrePrestador		varchar(50) UNIQUE NOT NULL, --puede haber mismo prestador ofreciendo distintos planes? - ni idea, je
		planPrestador		varchar(50) NOT NULL,
		activo				bit default 1,
		id_cobertura		int,
		CONSTRAINT fk_prestadorCobertura FOREIGN KEY (id_cobertura) REFERENCES dbHospital.cobertura (id_cobertura),
		--CONSTRAINT ck_idPrestador CHECK (LEN (id_prestador) = 3)
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
	CREATE TABLE dbHospital.tipoTurno(
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
		id_sede			 int IDENTITY (1,1) PRIMARY KEY, --no viene en carga masiva, hacer identity? -> en efecto
		nombreDeSede	 varchar(30) NOT NULL,
		direccionSede	 varchar(80) NOT NULL
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

--en inserccion no tengo id de especialidad... hacerlo identity? -> en efecto
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
--deberiamos borrar idmedico, SEGUN ARCHIVO nroMatricula es unico,se puede usar como id para cargar en la inserccion y que no de error por id_medico null, es siempre de 6 digitos aplicar check
--los nombres siempre arrancan con Dr. o Dra. podria aplicarse check
--apellidos siempre arrancan con mayuscula, no creo que haga falta check pero considerar para comparaciones en inserccion

--CREATE OR ALTER FUNCTION fnHospital.validarHorario(
--    @id_medico INT,
--    @id_sede_atencion INT,
--    @dia DATE,
--    @horaInicio TIME
--)
--RETURNS BIT
--AS
--BEGIN
--    DECLARE @Valido BIT = 1;

--    IF EXISTS (
--        SELECT 1
--        FROM dbHospital.diasXsede AS t_anterior
--        WHERE t_anterior.id_medico = @id_medico
--            AND t_anterior.id_sede_atencion = @id_sede_atencion
--            AND t_anterior.dia = @dia
--            AND (
--                @horaInicio = DATEADD(MINUTE, 15, t_anterior.horaInicio)
--                OR
--                (
--                    NOT EXISTS (
--                        SELECT 1
--                        FROM dbHospital.diasXsede AS primer_turno
--                        WHERE primer_turno.id_medico = @id_medico
--                            AND primer_turno.id_sede_atencion = @id_sede_atencion
--                            AND primer_turno.dia = @dia
--                            AND primer_turno.horaInicio < @horaInicio
--                    )
--                )
--            )
--    )
--	BEGIN
--		 SET @Valido = 0;
--		 RETURN @Valido;
--	END
--   ELSE
--		RETURN @Valido;
--END;
CREATE OR ALTER FUNCTION fnHospital.validarHorario(
    @id_medico			int,
    @id_sede_atencion	int,
    @dia			    date,
    @horaInicio			time
)
RETURNS BIT
AS
BEGIN
    DECLARE @valido bit = 1;

    IF EXISTS (
        SELECT 1
        FROM dbHospital.diasXsede AS t_anterior
        WHERE t_anterior.id_medico = @id_medico
            AND t_anterior.id_sede_atencion = @id_sede_atencion
            AND t_anterior.dia = @dia 
			AND (@horaInicio = CAST(DATEADD(MINUTE, 15, t_anterior.horaInicio) AS time)
			  OR
                (
                    NOT EXISTS (
                        SELECT 1
                        FROM dbHospital.diasXsede AS primer_turno
                        WHERE primer_turno.id_medico = @id_medico
                            AND primer_turno.id_sede_atencion = @id_sede_atencion
                            AND primer_turno.dia = @dia
                            AND primer_turno.horaInicio < @horaInicio
                    )
                )
            )
		)
    
    BEGIN
        SET @valido = 0;
        RETURN @valido;
    END

    RETURN @valido;
END;
GO

--tabla dias x sede
IF NOT EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'diasXsede' AND schema_id = SCHEMA_ID('dbHospital')) 
BEGIN
	CREATE TABLE dbHospital.diasXsede(
		id_dia_sede		int PRIMARY KEY,--que criterio tienen los ID de las sede?
		dia				date NOT NULL, 
		horaInicio		time NOT NULL, 
		id_medico	    int,
		id_sede_atencion int,
	   CONSTRAINT chk_horaInicio CHECK(fnHospital.validarHorario(id_medico, id_sede_atencion, dia, horaInicio) = 0),
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
	
		CONSTRAINT fk_reservaDiasxSede FOREIGN KEY (id_diaSede) REFERENCES dbHospital.diasXsede (id_dia_sede),
		CONSTRAINT fk_reservaPaciente FOREIGN KEY (id_paciente) REFERENCES dbHospital.paciente (id_historia_clinica),
		CONSTRAINT fk_reservaEstadoTurno FOREIGN KEY (id_estado) REFERENCES dbHospital.estadoTurno (id_estado_turno),
		CONSTRAINT fk_reservaTipoTurno FOREIGN KEY (id_tipoTurno) REFERENCES dbHospital.tipoTurno(id_tipo_turno),
		CONSTRAINT fk_reservaMedico FOREIGN KEY (id_medico) REFERENCES dbHospital.medico (id_medico),
		CONSTRAINT fk_reservaEspecialidadMed FOREIGN KEY (id_especialidad) REFERENCES dbHospital.especialidad (id_especialidad),
		CONSTRAINT fk_reservaSede FOREIGN KEY (id_sedeAten) REFERENCES dbHospital.sedeDeAtencion (id_sede)
	);
END
GO

--******************************************************************************************

--tabla Autorizacion requerida por la carga masiva de autorizaciones
IF NOT EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'autorizacion' AND schema_id = SCHEMA_ID('dbHospital')) 
BEGIN
	CREATE TABLE dbHospital.autorizacion(
		id_autorizacion		varchar (30) PRIMARY KEY,
		id_prestador		varchar (50) NOT NULL,
		area				varchar (50) NOT NULL,
		estudio				varchar (50) NOT NULL,
		plann				varchar (50) NOT NULL,
		porcCobertura		smallint NOT NULL,
		costo				int NOT NULL,
		actualizacion		varchar (10) NOT NULL,
		
		CONSTRAINT fk_autorizacionEstudio FOREIGN KEY (id_prestador) REFERENCES dbHospital.prestador (id_prestador)
);
END
GO
--Falta vincularla por fk con estudio, pero depende de como se plantee la tabla, discutir con grupo


--***********************************************************************************************************


-- ***************************** STORE PROCEDURES **************************


-- ***************************** INSERCION DE DATOS **************************
CREATE OR ALTER PROCEDURE spHospital.insercionDatos(
		@nombreEsquema nvarchar(128),   -- Nombre del esquema /PUEDE SER OPCIONAL, DEPENDIENDO DE LA FORMA QUE TOMEMOS
		@nombreTabla nvarchar(128),  -- Variable que contendra el nombre de la tabla a insertar
		@campos nvarchar(MAX),    -- Variable que contiene los nombres de los campos a ingresar datos
		@valores nvarchar(MAX)  -- Variable que contiene la lista de valores
		)
		AS    
	BEGIN
		-- Inicio de la sección TRY para manejo de errores
		BEGIN TRY
			-- Declaración de una variable para almacenar la consulta SQL dinámica
		
			DECLARE @sql nvarchar(MAX);

			-- Construcción de la consulta de inserción utilizando SQL dinámico
			--forma 1, con el esquema  pasado como parametro
			SET @sql = N'INSERT INTO '+ QUOTENAME(@nombreEsquema)+'.'+QUOTENAME(@nombreTabla)+
			'(' + @campos + ') VALUES (' + @valores + ');';
			
			-- Ejecución de la consulta SQL dinámica
			EXEC sp_executesql @sql; --  sp_executesql permite ejecutar SQL dinámico con seguridad, especialmente cuando se pasan parámetros.
		END TRY
			-- Inicio de la sección CATCH para manejo de errores
		BEGIN CATCH
			-- Declaración de variables para capturar el mensaje y detalles del error
			DECLARE @mensajeError nvarchar(4000);
			DECLARE @gravedadDelError int;
			DECLARE @estadoDelError int;

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
    @nombreEsquema nvarchar(128), -- Nombre del esquema 
    @nombreTabla nvarchar(128),-- Variable que contendra el nombre de la tabla a modificar
    @clausulaSet nvarchar(MAX), -- Variable que contiene el contenido de la clausula set
    @clausulaWhere nvarchar(MAX)-- Variable que contiene el contenido de la clausula where
	) 
	AS
BEGIN
    BEGIN TRY
        DECLARE @sql nvarchar(MAX);

        -- Construcción de la consulta de actualización utilizando SQL dinámico
        SET @sql = N'UPDATE ' + QUOTENAME(@nombreEsquema) + '.' + QUOTENAME(@nombreTabla) +
                   N' SET ' + @clausulaSet +
                   N' WHERE ' + @clausulaWhere + ';';

        -- Ejecución de la consulta SQL dinámica
        EXEC sp_executesql @sql;
    END TRY
	BEGIN CATCH
			-- Declaración de variables para capturar el mensaje y detalles del error
		DECLARE @mensajeError nvarchar(4000);
		DECLARE @gravedadDelError int;
		DECLARE @estadoDelError int;

			-- Obtención de los detalles del error ocurrido
		SELECT @mensajeError = ERROR_MESSAGE(),
			   @gravedadDelError = ERROR_SEVERITY(),
			   @estadoDelError = ERROR_STATE();
			-- Lanzamiento del error capturado para informar del fallo
		RAISERROR (@mensajeError, @gravedadDelError, @estadoDelError);
	END CATCH;
END
GO

-- ***************************** ELIMINACION DE DATOS **************************
CREATE OR ALTER PROCEDURE spHospital.borrarDatos(
    @nombreEsquema	nvarchar(128),  -- Nombre del esquema
    @nombreTabla	nvarchar(128),   -- Nombre de la tabla
    @clausuraWhere	nvarchar(MAX)  -- Condición para la eliminación
	)
	AS
BEGIN
    BEGIN TRY
        DECLARE @sql nvarchar(MAX);

        -- Construcción de la consulta de eliminación utilizando SQL dinámico
        SET @sql = N'DELETE FROM ' + QUOTENAME(@nombreEsquema) + N'.' + QUOTENAME(@nombreTabla) +
                   N' WHERE ' + @clausuraWhere + N';';

        -- Ejecución de la consulta SQL dinámica
        EXEC sp_executesql @sql;
    END TRY
    BEGIN CATCH
		-- Declaración de variables para capturar el mensaje y detalles del error
		DECLARE @mensajeError	  nvarchar(4000);
		DECLARE @gravedadDelError int;
		DECLARE @estadoDelError	  int;
		-- Obtención de los detalles del error ocurrido
		SELECT @mensajeError = ERROR_MESSAGE(),
			   @gravedadDelError = ERROR_SEVERITY(),
			   @estadoDelError = ERROR_STATE();
		-- Lanzamiento del error capturado para informar del fallo
		RAISERROR (@mensajeError, @gravedadDelError, @estadoDelError);
	END CATCH;
END
GO

--*********CREACION DE ROLES***********
--ACLARACION: No hace falta aclarar esquema, los roles son aplicados a nivel base de datos.
--TENGO QUE DROPEARLOS PORQUE NO SE GUARDAN A NIVEL BD, CADA VEZ QUE REINICIO LA BD PARA PROBAR SU FUNCIONAMIENTO VA A SALTAR ERROR
--PORQUE YA EXISTEN LOS USUARIOS....
IF  NOT EXISTS ( SELECT 1 FROM sys.database_principals  WHERE name = 'Paciente') 
	BEGIN
	EXEC ('CREATE ROLE Paciente;');
	END
GO

IF NOT EXISTS ( SELECT 1 FROM sys.database_principals  WHERE name = 'Medico') 
	BEGIN
	EXEC ('CREATE ROLE Medico;');
	END
GO

IF NOT EXISTS ( SELECT 1 FROM sys.database_principals  WHERE name = 'Personal Administrativo') 
	BEGIN
	EXEC ('CREATE ROLE [Personal Administrativo];')
	END
GO

IF NOT EXISTS ( SELECT 1 FROM sys.database_principals  WHERE name = 'Personal Tecnico clinico') 
	BEGIN
	EXEC('CREATE ROLE [Personal Tecnico clinico];');
	END
GO

IF NOT EXISTS ( SELECT 1 FROM sys.database_principals  WHERE name = 'Administrador General') 
	BEGIN
	EXEC('CREATE ROLE [Administrador General];');
	END
GO

--*********USUARIOS-LOGIN Y PERMISOS DE ROLES**********

--no se aclara en tp por lo que lo hacemos a consideracion de nuestra opinion
--para paciente no se como hacer que solo pueda ver sus datos... hay que crear alguna vista

--los demas no funcionaban porque no se habia creado un user relacionado al rol...

--CREACION DE USUARIO Y LOGIN EN PACIENTE
IF NOT EXISTS ( SELECT 1 FROM sys.server_principals  WHERE name = 'PacienteLog') 
	BEGIN
	EXEC ('CREATE LOGIN PacienteLog
	WITH PASSWORD = ''1234'';');
	END
GO
IF NOT EXISTS ( SELECT 1 FROM sys.database_principals  WHERE name = 'Milanesa') 
BEGIN
EXEC ('CREATE USER Milanesa
FOR LOGIN PacienteLog');
END
GO
Alter role Paciente add member Milanesa
GO

--Aca van los permisos de paciente, no solucionado todavia...

--CREACION DE USUARIO Y LOGIN EN MEDICO
IF NOT EXISTS ( SELECT 1 FROM sys.server_principals  WHERE name = 'Medico') 
BEGIN
EXEC ('CREATE LOGIN Medico
WITH PASSWORD = ''Contrasenia poderosa'';');
END
GO
IF NOT EXISTS ( SELECT 1 FROM sys.database_principals  WHERE name = '[Dr.Messi]') 
BEGIN
EXEC ('CREATE USER [Dr.Messi]
FOR LOGIN Medico;');
END
GO
Alter role Paciente add member [Dr.Messi]
GO
--PERMISOS MEDICO
GRANT EXECUTE ON spHospital.insercionDatos TO Medico;
GRANT SELECT ON dbHospital.paciente TO Medico;
GRANT SELECT ON dbHospital.estudio TO Medico;
GRANT SELECT ON dbHospital.cobertura TO Medico;
GO

--CREACION DE USUARIO Y LOGIN EN ADMINISTRATIVO

IF NOT EXISTS ( SELECT 1 FROM sys.server_principals  WHERE name = 'Administrativo') 
BEGIN
EXEC ('CREATE LOGIN Administrativo
WITH PASSWORD = ''Contrasenia fuerte'';');
END
GO
IF NOT EXISTS ( SELECT 1 FROM sys.database_principals  WHERE name = 'Batman') 
BEGIN
EXEC ('CREATE USER Batman
FOR LOGIN Administrativo;');
END
GO
Alter role [Personal Administrativo] add member Batman
GO
--PERMISOS ADMINISTRATIVO
GRANT EXECUTE ON spHospital.borrarDatos TO [Personal Administrativo]; --peligrosa, pero no le podemos dejar solo el borrador a administrador general...
GRANT EXECUTE ON spHospital.modificacionDatos TO [Personal Administrativo];
GRANT EXECUTE ON spHospital.insercionDatos TO [Personal Administrativo];
GRANT SELECT ON dbHospital.paciente TO [Personal Administrativo];
GRANT SELECT ON dbHospital.reservaTurnoMedico TO [Personal Administrativo];
GRANT SELECT ON dbHospital.cobertura TO [Personal Administrativo];
GRANT SELECT ON dbHospital.prestador TO [Personal Administrativo];
GRANT SELECT ON dbHospital.estadoTurno TO [Personal Administrativo];
GRANT SELECT ON dbHospital.tipoTurno TO [Personal Administrativo];
GRANT SELECT ON dbHospital.medico TO [Personal Administrativo];
GRANT SELECT ON dbHospital.especialidad TO [Personal Administrativo];
GO

--CREACION DE USUARIO Y LOGIN EN TECNICO CLINICO
IF NOT EXISTS ( SELECT 1 FROM sys.server_principals  WHERE name = '[Tecnico Clinico]') 
BEGIN
EXEC ('CREATE LOGIN [Tecnico Clinico]
WITH PASSWORD = ''Contrasenia media'';');
END
GO
IF NOT EXISTS ( SELECT 1 FROM sys.database_principals  WHERE name = 'Ayudante') 
BEGIN
EXEC('CREATE USER Ayudante
FOR LOGIN [Tecnico Clinico];')
END
GO
Alter role [Personal Tecnico clinico] add member Ayudante
GO
--PERMISOS DE TECNICO CLINICO
GRANT EXECUTE ON spHospital.insercionDatos to [Personal Tecnico clinico];
--GRANT SELECT ON dbHosptial.paciente TO [Personal Tecnico clinico]; --error en esta y abajo
--GRANT SELECT ON dbHosptial.estudio TO [Personal Tecnico clinico];
GO

--CREACION DE USUARIO Y LOGIN EN ADMINISTRADOR GENERAL
IF NOT EXISTS ( SELECT 1 FROM sys.server_principals  WHERE name = 'Admi') 
BEGIN
EXEC ('CREATE LOGIN Admi
WITH PASSWORD = ''Contrasenia indescifrable'';');
END
GO
IF NOT EXISTS ( SELECT 1 FROM sys.database_principals  WHERE name = 'Jair') 
BEGIN
EXEC('CREATE USER Jair
FOR LOGIN Admi;');
END
GO
Alter role [Administrador General] add member Jair
GO

--PERMISOS DE ADMINISTRADOR GENERAL

--GRANT CONTROL ON SERVER TO [Administrador General]; --error
--GO


--******************************Importacion de archivos******************************************

--IMPORTACION DE ESPECIALIDAD CON ARCHIVO DE MEDICO
CREATE OR ALTER PROCEDURE spHospital.ArchivoEspecialidad (
	@rutaCSV nvarchar(500)
	)
AS
	SET NOCOUNT ON;
	-- Trabajamos con tabla temporal para poder tomar los datos del archivo y modificarlos para su proxima inserccion, luego la borramos
	--por ejemplo, la especialidad la tenemos que sacar del archivo de medico, pero tiene mas datos que solo eso, tiene la siguiente estructura:
	IF OBJECT_ID('tempdb..#CSV_Medico') IS NULL
	BEGIN
		CREATE TABLE #CSV_Medico (
			nombre			varchar(30) NOT NULL,
			apellido		varchar(30) NOT NULL,
			especialidad	varchar(50) NOT NULL,
			nroColegiado	varchar(6) NOT NULL,  --se ve que es 6 en archivo, podemos aplicar un check en tabla original? nroColegiado=Matricula
		)
	END
	-- Declarar variables
	DECLARE @insercion  AS nvarchar(MAX),
			@mensaje	AS varchar(250),
		    @cant		AS int;
	
	-- Insertar valores del csv en la tabla temporal
	SET @insercion = N'BULK INSERT #CSV_Medico FROM ''' + @rutaCSV + N''' WITH(CHECK_CONSTRAINTS, CODEPAGE = ''65001'', FIRSTROW = 2, FIELDTERMINATOR = '';'')'
	--codepage es con acp solo si estoy seguro de que la pagina de codigos activa de sistema contiene todos los caracteres que se encuentre en el archivo
	--firstrow arranca en 2 para saltear el encabezado... sino seria 1
	--fieldterminator es como se encuentran separados los elementos, se ve abriendo el archivo en un bloc de notas...
	BEGIN TRY
		BEGIN TRANSACTION
		
		EXEC sp_executesql @insercion --para evitar inyecciones

		INSERT INTO dbHospital.especialidad (nombreEspecialidad)
		SELECT DISTINCT M.especialidad COLLATE Modern_Spanish_CI_AI 
		FROM #CSV_Medico M
		WHERE NOT EXISTS (SELECT 1 FROM dbHospital.especialidad E
							WHERE M.especialidad = E.nombreEspecialidad COLLATE Modern_Spanish_CI_AI)
		
		SET @cant = @@ROWCOUNT;

		SET @mensaje = 'La tabla de especialidades ha recibido' + CAST(@cant AS varchar) + ' especialidades nuevas';
		PRINT @mensaje;

		--EXEC spCureSA.InsertarLog @texto = @ilog, @modulo = '[INSERT]'   es requisito documentar esto?

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
        -- Manejo de errores
        DECLARE @mensajeError		nvarchar(4000);
        DECLARE @gravedadDeError	int;
        DECLARE @estadoDelError		int;

        SELECT @mensajeError = ERROR_MESSAGE(),
               @gravedadDeError = ERROR_SEVERITY(),
               @estadoDelError = ERROR_STATE();

        -- Lanzar el error
        RAISERROR (@mensajeError, @gravedadDeError, @estadoDelError);
		IF @@TRANCOUNT > 0
		--variable del sistema, indica si hay una transaccion activa 
		ROLLBACK TRANSACTION
    END CATCH;
	DROP TABLE #CSV_Medico
	SET NOCOUNT OFF;

GO


--IMPORTACION DE MEDICOS CON ARCHIVO DE MEDICO
CREATE OR ALTER PROCEDURE spHospital.ArchivoMedico (
	@rutaCSV nvarchar(500)
	)
AS
	SET NOCOUNT ON;
	IF OBJECT_ID('tempdb..#CSV_Medico') IS NULL
	BEGIN
		CREATE TABLE #CSV_Medico (
			nombre			varchar(30) NOT NULL,
			apellido		varchar(30) NOT NULL,
			especialidad	varchar(40) NOT NULL,
			nroColegiado	varchar(8) NOT NULL,
			)
	END
	-- Declarar variables
	DECLARE @insercion	AS nvarchar(MAX)
		, @mensaje		AS varchar(250)
		, @cant			AS int;
	
	-- Insertar valores del csv en la tabla temporal
	SET @insercion = N'BULK INSERT #CSVMedico FROM ''' + @rutaCSV + N''' WITH(CHECK_CONSTRAINTS, CODEPAGE = ''65001'', FIRSTROW = 2, FIELDTERMINATOR = '';'')'
	BEGIN TRY
		BEGIN TRANSACTION
		
		EXEC sp_executesql @insercion

		-- TRANSFORMACION DE DATOS
		UPDATE #CSV_Medico
		SET especialidad = UPPER(especialidad) --es necesario? no tenemos ninguna condicion que nos oblige
		
		UPDATE #CSV_Medico
		SET nombre = UPPER(nombre) --es necesario? no tenemos ninguna condicion que nos oblige

		INSERT INTO dbHospital.medico (id_medico,nombre,apellido,nroMatricula)
		SELECT E.id_especialidad,M.nombre, M.apellido,M.nroColegiado
		FROM #CSV_Medico M join dbHospital.especialidad E ON M.especialidad=E.nombreEspecialidad
		WHERE NOT EXISTS ( SELECT 1 FROM dbHospital.medico Mm
									WHERE M.nroColegiado=Mm.nroMatricula
		) 
		
		SET @cant = @@ROWCOUNT;

		SET @mensaje = 'La tabla de medicos ha recibido' + CAST(@cant AS varchar) + ' registros nuevos';
		PRINT @mensaje;

		--EXEC spCureSA.InsertarLog @texto = @ilog, @modulo = '[INSERT]'   es requisito documentar esto?

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
        -- Manejo de errores
        DECLARE @mensajeError	 nvarchar(4000);
        DECLARE @gravedadDeError int;
        DECLARE @estadoDelError	 int;

        SELECT @mensajeError = ERROR_MESSAGE(),
               @gravedadDeError = ERROR_SEVERITY(),
               @estadoDelError = ERROR_STATE();

        -- Lanzar el error
        RAISERROR (@mensajeError, @gravedadDeError, @estadoDelError);
		IF @@TRANCOUNT > 0
		--variable del sistema, indica si hay una transaccion activa 
		ROLLBACK TRANSACTION
    END CATCH;
	
	DROP TABLE #CSV_Medico
	SET NOCOUNT OFF;
GO


--IMPORTACION DE SEDES CON ARCHIVO DE SEDES
CREATE OR ALTER PROCEDURE spHospital.ArchivoSede @rutaCSV nvarchar(500)
AS
	SET NOCOUNT ON;
	IF OBJECT_ID('tempdb..#CSV_Sede') IS NULL
	BEGIN
		CREATE TABLE #CSV_Sede (
			Sede		varchar(30) NOT NULL,
			Direccion	varchar(30) NOT NULL,
			Localidad	varchar(30) NOT NULL,
			Provincia	varchar(30) NOT NULL,
			)
	END
	-- Declarar variables
	DECLARE @insercion	 AS nvarchar(MAX),
			@mensaje	 AS varchar(250),
			@cant		 AS int;
	
	-- Insertar valores del csv en la tabla temporal
	SET @insercion = N'BULK INSERT #CSV_Sede FROM ''' + @rutaCSV + N''' WITH(CHECK_CONSTRAINTS, CODEPAGE = ''65001'', FIRSTROW = 2, FIELDTERMINATOR = '';'')'
	BEGIN TRY
		BEGIN TRANSACTION
		
		EXEC sp_executesql @insercion

		-- TRANSFORMACION DE DATOS
		--sede solo posee 3 campos, id;nombre;direccion. Voy a tener que modificar los datos para poder insertalos correctamente en la tabla
		UPDATE #CSV_Sede
		SET Direccion = Direccion + ',' + Localidad + ',' + Provincia
		
		
		INSERT INTO dbHospital.sedeDeAtencion (nombreDeSede,direccionSede) --y id como hago?, como direccion es sumatoria voy a aumentar campo original
		SELECT S.Sede,S.Direccion
		FROM #CSV_Sede S 
		WHERE NOT EXISTS ( SELECT 1 FROM dbHospital.sedeDeAtencion SA
							WHERE S.Sede=SA.nombreDeSede and S.Direccion = SA.direccionSede
		)
		SET @cant = @@ROWCOUNT;

		SET @mensaje = 'La tabla de sedes ha recibido ' + CAST(@cant AS varchar) + ' sedes nuevas';
		PRINT @mensaje;

		--EXEC spCureSA.InsertarLog @texto = @ilog, @modulo = '[INSERT]'   es requisito documentar esto?

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
        -- Manejo de errores
        DECLARE @mensajeError		nvarchar(4000);
        DECLARE @gravedadDeError	int;
        DECLARE @estadoDelError		int;

        SELECT @mensajeError = ERROR_MESSAGE(),
               @gravedadDeError = ERROR_SEVERITY(),
               @estadoDelError = ERROR_STATE();

        -- Lanzar el error
        RAISERROR (@mensajeError, @gravedadDeError, @estadoDelError);
		IF @@TRANCOUNT > 0
		--variable del sistema, indica si hay una transaccion activa 
		ROLLBACK TRANSACTION
    END CATCH;

	DROP TABLE #CSV_Sede
	SET NOCOUNT OFF;
GO


--IMPORTACION DE PRESTADORES CON ARCHIVO DE PRESTADORES
CREATE OR ALTER PROCEDURE spHospital.ArchivoPrestador (
	@rutaCSV nvarchar(500)
	)
AS
	SET NOCOUNT ON;
	IF OBJECT_ID('tempdb..#CSV_Prestador') IS NULL
	BEGIN
		CREATE TABLE #CSV_Prestador (
			Prestador	varchar(50) NOT NULL,
			Plann		varchar(50) NOT NULL --plan es una instruccion, tengo que copiarlo diferente
			)
	END
	-- Declarar variables
	DECLARE @insercion	AS Nvarchar(MAX),
			 @mensaje	AS varchar(250),
			 @cant		AS INT;
	
	-- Insertar valores del csv en la tabla temporal
	SET @insercion = N'BULK INSERT #CSV_Prestador FROM ''' + @rutaCSV + N''' WITH(CHECK_CONSTRAINTS, CODEPAGE = ''65001'', FIRSTROW = 2, FIELDTERMINATOR = '';'')'
	BEGIN TRY
		BEGIN TRANSACTION
		
		EXEC sp_executesql @insercion

		INSERT INTO dbHospital.prestador (nombrePrestador,planPrestador)
		SELECT P.Prestador,P.Plann
		FROM #CSV_Prestador P 
		WHERE NOT EXISTS( SELECT 1 FROM dbHospital.prestador Pp
						  WHERE P.Prestador COLLATE Latin1_General_CI_AI = Pp.nombrePrestador COLLATE Latin1_General_CI_AI
						  and P.Plann COLLATE Latin1_General_CI_AI = Pp.planPrestador COLLATE Latin1_General_CI_AI
						)
		SET @cant = @@ROWCOUNT;

		SET @mensaje = 'La tabla prestador ha recibido' + CAST(@cant AS varchar) + ' prestadores y/o planes nuevos';
		PRINT @mensaje;

		--EXEC spCureSA.InsertarLog @texto = @ilog, @modulo = '[INSERT]'   es requisito documentar esto?

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
        -- Manejo de errores
        DECLARE @mensajeError		nvarchar(4000);
        DECLARE @gravedadDeError	int;
        DECLARE @estadoDelError		int;

        SELECT @mensajeError = ERROR_MESSAGE(),
               @gravedadDeError = ERROR_SEVERITY(),
               @estadoDelError = ERROR_STATE();

        -- Lanzar el error
        RAISERROR (@mensajeError, @gravedadDeError, @estadoDelError);
		IF @@TRANCOUNT > 0
		--variable del sistema, indica si hay una transaccion activa 
		ROLLBACK TRANSACTION
    END CATCH;

	DROP TABLE #CSV_Prestador
	SET NOCOUNT OFF;

GO

--IMPORTACION DE PACIENTES CON ARCHIVO DE PACIENTES
CREATE OR ALTER PROCEDURE spHospital.ArchivoPacientes (
	@rutaCSV nvarchar(500)
	)
AS
	SET NOCOUNT ON;
	IF OBJECT_ID('tempdb..#CSV_Paciente') IS NULL
	BEGIN
		CREATE TABLE #CSV_Paciente (
			nombre			varchar(30) NOT NULL,
			apellido		varchar(30) NOT NULL,
			fechaNacimiento date NOT NULL,
			tipoDocumento	varchar (10) NOT NULL, 
			nroDocumento	char (8) NOT NULL, 
			sexoBio			varchar(9) NOT NULL, 
			genero			varchar (20) NOT NULL, 
			telefonoFijo	char(14) NOT NULL,
			nacionalidad	varchar (20) NOT NULL,
			mail			varchar (50) NOT NULL,
			calle_y_nro		varchar(50) NOT NULL,
			localidad		varchar (30) NOT NULL,
			provincia		varchar (20) NOT NULL,
			)
	END
	-- Declarar variables
	DECLARE @insercion AS nvarchar(MAX),
			@mensaje AS varchar(250),
			@cant AS int;
	
	-- Insertar valores del csv en la tabla temporal
	SET @insercion = N'BULK INSERT #CSV_Paciente FROM ''' + @rutaCSV + N''' WITH(CHECK_CONSTRAINTS, CODEPAGE = ''65001'', FIRSTROW = 2, FIELDTERMINATOR = '';'')'
	BEGIN TRY
		BEGIN TRANSACTION
		
		EXEC sp_executesql @insercion

		INSERT INTO dbHospital.paciente (nombre,apellido,fechaNacimiento,tipoDoc,numDoc,sexoBio,genero,telFijo,nacionalidad,mail)--y el id paciente? tiene identity, no deberia dar problema al momento de insertar no?
		SELECT P.nombre,P.apellido,P.fechaNacimiento,P.tipoDocumento,P.nroDocumento,P.sexoBio,P.genero,P.telefonoFijo,P.nacionalidad,P.mail
		FROM #CSV_Paciente P 
		WHERE NOT EXISTS ( SELECT 1 FROM dbHospital.paciente Pp
									WHERE P.NroDocumento=Pp.numDoc)
		SET @cant = @@ROWCOUNT;

		SET @mensaje = 'La tabla pacientes ha recibido' + CAST(@cant AS varchar) + ' pacientes nuevos';
		PRINT @mensaje;

		--EXEC spCureSA.InsertarLog @texto = @ilog, @modulo = '[INSERT]'   es requisito documentar esto?

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
        -- Manejo de errores
        DECLARE @mensajeError		nvarchar(4000);
        DECLARE @gravedadDeError	int;
        DECLARE @estadoDelError	    int;

        SELECT @mensajeError = ERROR_MESSAGE(),
               @gravedadDeError = ERROR_SEVERITY(),
               @estadoDelError = ERROR_STATE();

        -- Lanzar el error
        RAISERROR (@mensajeError, @gravedadDeError, @estadoDelError);
		IF @@TRANCOUNT > 0
		--variable del sistema, indica si hay una transaccion activa 
			ROLLBACK TRANSACTION
    END CATCH;
	
	DROP TABLE #CSV_Paciente
	SET NOCOUNT OFF;

GO

--usuarios no es requerimiento, lo dejamos a carga manual?

--IMPORTACION DE DOMICILIOS CON ARCHIVO DE PACIENTES
CREATE OR ALTER PROCEDURE spHospital.ArchivoDomicilio (
	@rutaCSV nvarchar(500)
	)
AS
	SET NOCOUNT ON;
	IF OBJECT_ID('tempdb..#CSV_Paciente') IS NULL
	BEGIN
		CREATE TABLE #CSV_Paciente (
			nombre			varchar(30) NOT NULL,
			apellido		varchar(30) NOT NULL,
			fechaNacimiento date NOT NULL, 
			tipoDocumento	varchar (10) NOT NULL, 
			nroDocumento	char (8) NOT NULL,
			sexoBio			char NOT NULL, 
			genero			varchar (20) NOT NULL, 
			telefonoFijo	char(14) NOT NULL,
			nacionalidad	varchar (20) NOT NULL,
			mail			varchar (50) NOT NULL,
			calle_y_nro		varchar(50) NOT NULL,
			localidad		varchar (30) NOT NULL,
			provincia		varchar (20) NOT NULL,
			)
	END
	-- Declarar variables
	DECLARE @insercion	AS nvarchar(MAX),
			 @mensaje	AS varchar(250),
			@cant		AS int;
	
	-- Insertar valores del csv en la tabla temporal
	SET @insercion = N'BULK INSERT #CSV_Paciente FROM ''' + @rutaCSV + N''' WITH(CHECK_CONSTRAINTS, CODEPAGE = ''65001'', FIRSTROW = 2, FIELDTERMINATOR = '';'')'
	BEGIN TRY
		BEGIN TRANSACTION
		
		EXEC sp_executesql @insercion

		INSERT INTO dbHospital.domicilio (calle,numero,localidad,provincia)
		SELECT LEFT(P.calle_y_nro, LEN(P.calle_y_nro) - CHARINDEX(' ', REVERSE(P.calle_y_nro + ' '))) AS calle,
			   RIGHT(P.calle_y_nro, CHARINDEX(' ', REVERSE(P.calle_y_nro + ' ')) - 1) AS nro,
			   P.Localidad, P.Provincia
		FROM #CSV_Paciente P 
		WHERE NOT EXISTS ( SELECT 1 FROM dbHospital.domicilio D
									WHERE P.Calle_y_nro COLLATE Latin1_General_CI_AI = (D.calle + ' ' +D.numero)COLLATE Latin1_General_CI_AI)
		SET @cant = @@ROWCOUNT;

		SET @mensaje = 'La tabla domicilios ha recibido' + CAST(@cant AS varchar) + ' domicilios nuevos';
		PRINT @mensaje;

		--EXEC spCureSA.InsertarLog @texto = @ilog, @modulo = '[INSERT]'   es requisito documentar esto?

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
        -- Manejo de errores
        DECLARE @mensajeError		nvarchar(4000);
        DECLARE @gravedadDeError	int;
        DECLARE @estadoDelError		int;

        SELECT @mensajeError = ERROR_MESSAGE(),
               @gravedadDeError = ERROR_SEVERITY(),
               @estadoDelError = ERROR_STATE();

        -- Lanzar el error
        RAISERROR (@mensajeError, @gravedadDeError, @estadoDelError);
		IF @@TRANCOUNT > 0
		--variable del sistema, indica si hay una transaccion activa 
		ROLLBACK TRANSACTION
    END CATCH;

	DROP TABLE #CSV_Paciente
	SET NOCOUNT OFF;

GO

--IMPORTACION DE AUTORIZACIONES CON ARCHIVO DE AUTORIZACIONES
--para el siguiente proc de autorizaciones hay que crear tabla autorizaciones... a menos que no la haya visto...
CREATE OR ALTER PROCEDURE spHospital.ArchivoAutorizacion (
	@rutaJ NVARCHAR(500)
	)
AS
	SET NOCOUNT ON;
	IF OBJECT_ID('tempdb..#J_Autorizacion') IS NULL
	BEGIN
		CREATE TABLE #J_Autorizacion (
			columna nvarchar(max)
		)
	END
	IF OBJECT_ID('tempdb..#J_Comprobacion') IS NULL
	BEGIN
		--se puede trabajar con mas de una columna, pero esto da sencillez al proceso. Si fueran datos mas complejos quizas si combiene descomponer los datos en varias columnas
		CREATE TABLE #J_Comprobacion (
			id			int,
			area		varchar(50),
			estudio		varchar(50),
			prestador	varchar(50),
			plann		varchar(50),
			porcCobertura smallint,
			costo		int,
			actualizacion varchar(10)
			);
	END
-- Declarar variables
DECLARE @insercion	 AS nvarchar(MAX),
	    @mensaje	 AS varchar(250),
		@cant		 AS int;
	
BEGIN TRY
		BEGIN TRANSACTION
	-- Insertar valores del J en la tabla temporal
	EXEC sp_executesql @insercion;

	INSERT INTO #J_Comprobacion (id,area,estudio,prestador,plann,porcCobertura,costo,actualizacion)
	SELECT	JSON_VALUE(columna, '$._id.$oid') AS id,
			JSON_VALUE(columna, '$.Area') AS area,
			JSON_VALUE(columna, '$.Estudio') AS estudio,
			JSON_VALUE(columna, '$.Prestador') AS prestador,
			JSON_VALUE(columna, '$.Plan') AS plann,
			JSON_VALUE(columna, '$."Porcentaje Cobertura"') AS porc_cobertura,
			JSON_VALUE(columna, '$.Costo') AS costo,
			JSON_VALUE(columna, '$."Requiere autorizacion"') AS actualizacion
		FROM #J_Autorizacion

	INSERT INTO dbHospital.autorizacion (id_autorizacion,area,estudio, prestador, plann, porcCobertura, costo, actualizacion)
	SELECT 
		C.id,
		C.area,
		C.estudio,
		C.prestador,
		C.plann,
		C.porcCobertura,
		C.costo,
		C.actualizacion
	FROM #J_Comprobacion C
	WHERE NOT EXISTS ( SELECT 1 FROM dbHospital.autorizacion A	
									WHERE A.id_autorizacion=C.id);

DROP TABLE #J_Comprobacion

SET @cant = @@ROWCOUNT;

		SET @mensaje = 'La tabla autorizaciones ha recibido' + CAST(@cant AS varchar) + ' cargas nuevas';
		PRINT @mensaje;

		--EXEC spCureSA.InsertarLog @texto = @ilog, @modulo = '[INSERT]'   es requisito documentar esto?

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
        -- Manejo de errores
        DECLARE @mensajeError		nvarchar(4000);
        DECLARE @gravedadDeError	int;
        DECLARE @estadoDelError	    int;

        SELECT @mensajeError = ERROR_MESSAGE(),
               @gravedadDeError = ERROR_SEVERITY(),
               @estadoDelError = ERROR_STATE();

        -- Lanzar el error
        RAISERROR (@mensajeError, @gravedadDeError, @estadoDelError);
		IF @@TRANCOUNT > 0
		--variable del sistema, indica si hay una transaccion activa 
			ROLLBACK TRANSACTION
    END CATCH;

	DROP TABLE #J_Autorizacion
	SET NOCOUNT OFF;

GO
--**************************************************************************************************************************
DECLARE @nombreObraSocial varchar(50) = 'Nombre del plan de la obra social';   -- Modificar estos campos según la consulta que se quiera hacer
DECLARE @fechaInicio date = '2024-06-01';                                       
DECLARE @fechaFin date = '2024-06-30';                                           

SELECT 
    P.id_historia_clinica AS '@PacienteId',
    P.apellido AS 'PacienteApellido',
    P.nombre AS 'PacienteNombre',
    P.numDoc AS 'PacienteDNI',
    M.nombre AS 'MedicoNombre',
    M.nroMatricula AS 'MedicoMatricula',
    RT.fecha AS 'Fecha',
    RT.hora AS 'Hora',
    E.nombreEspecialidad AS 'Especialidad'
FROM 
		dbHospital.paciente P
	INNER JOIN 
		dbHospital.reservaTurnoMedico RT ON P.id_historia_clinica = RT.id_paciente
	INNER JOIN 
		dbHospital.medico M ON RT.id_medico = M.id_medico
	INNER JOIN 
		dbHospital.especialidad E ON RT.id_especialidad = E.id_especialidad
	INNER JOIN 
		dbHospital.estadoTurno ET ON RT.id_estado = ET.id_estado_turno
	INNER JOIN 
		dbHospital.cobertura C ON P.id_historia_clinica = C.id_hist_clinica  
	INNER JOIN                                                                 
		dbHospital.prestador PR ON C.id_cobertura = PR.id_cobertura
WHERE 
    RT.fecha BETWEEN @fechaInicio AND @fechaFin
    AND PR.nombrePrestador = @nombreObraSocial
    AND UPPER(ET.estado) = 'ATENDIDO'
FOR XML PATH('Paciente'), ROOT('Turno')
