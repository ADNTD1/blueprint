-- ============================================================================
-- SCRIPT DE DATOS DE PRUEBA (SEED) PARA BLUEPRINT
-- ============================================================================
-- INSTRUCCIONES:
-- 1. Copia tu "User ID" desde Supabase (Pestaña Authentication > Users)
-- 2. Remplaza el 'PON_TU_USER_ID_AQUI' de abajo por tu ID real.
-- 3. Corre este script en el SQL Editor de Supabase.

DO $$
DECLARE
    -- ¡¡¡ CAMBIA ESTO POR EL ID DE TU USUARIO EN SUPABASE !!!
    v_user_id uuid := 'PON_TU_USER_ID_AQUI'; 
    v_org_id uuid;
    v_project_id uuid;
BEGIN

    IF v_user_id = 'PON_TU_USER_ID_AQUI' THEN
        RAISE EXCEPTION 'Debes cambiar la variable v_user_id por tu verdadero ID de Supabase antes de ejecutar el script.';
    END IF;

    -- 1. Crear Organización
    INSERT INTO public.organizations (name, created_by) 
    VALUES ('Acme Corp', v_user_id) 
    RETURNING id INTO v_org_id;

    -- 2. Agregarte a ti mismo como dueño de la org
    INSERT INTO public.organization_members (organization_id, user_id, member_role)
    VALUES (v_org_id, v_user_id, 'owner');

    -- ==============================================================
    -- PROYECTO 1: "Rediseño de Web" (Activo)
    -- ==============================================================
    INSERT INTO public.projects (organization_id, name, description, status, created_by)
    VALUES (v_org_id, 'Rediseño de Web', 'Migración completa de la web a Vue y Supabase', 'active', v_user_id)
    RETURNING id INTO v_project_id;

    -- Agregarte al proyecto 1
    INSERT INTO public.project_members (project_id, user_id, project_role)
    VALUES (v_project_id, v_user_id, 'manager');

    -- Tareas del Proyecto 1 (2 Completadas, 1 En Progreso, 1 Pendiente)
    INSERT INTO public.tasks (project_id, title, status_id, priority, created_by) VALUES
    (v_project_id, 'Definir paleta de colores', 3, 'high', v_user_id),
    (v_project_id, 'Configurar router de Vue', 3, 'medium', v_user_id),
    (v_project_id, 'Implementar Auth con Supabase', 2, 'high', v_user_id),
    (v_project_id, 'Crear vistas del Dashboard', 1, 'medium', v_user_id);

    -- ==============================================================
    -- PROYECTO 2: "Campaña Marketing Q3" (Activo)
    -- ==============================================================
    INSERT INTO public.projects (organization_id, name, description, status, created_by)
    VALUES (v_org_id, 'Campaña de Marketing', 'Lanzamiento Q3 Ads', 'active', v_user_id)
    RETURNING id INTO v_project_id;

    -- Agregarte al proyecto 2
    INSERT INTO public.project_members (project_id, user_id, project_role)
    VALUES (v_project_id, v_user_id, 'manager');

    -- Tareas del Proyecto 2
    INSERT INTO public.tasks (project_id, title, status_id, priority, created_by) VALUES
    (v_project_id, 'Revisar copies de anuncios', 1, 'high', v_user_id),
    (v_project_id, 'Diseñar banners estáticos', 2, 'medium', v_user_id);


    -- ==============================================================
    -- PROYECTO 3: "Migración Servidores" (Archivado)
    -- ==============================================================
    INSERT INTO public.projects (organization_id, name, description, status, created_by)
    VALUES (v_org_id, 'Migración Servidores', 'Pasar de AWS a Vercel', 'archived', v_user_id)
    RETURNING id INTO v_project_id;

    -- Agregarte al proyecto 3
    INSERT INTO public.project_members (project_id, user_id, project_role)
    VALUES (v_project_id, v_user_id, 'manager');

    -- Tareas del Proyecto 3 (Todas completadas)
    INSERT INTO public.tasks (project_id, title, status_id, priority, created_by) VALUES
    (v_project_id, 'Respaldar BD', 3, 'high', v_user_id),
    (v_project_id, 'Levantar instancias Vercel', 3, 'high', v_user_id);

END $$;
