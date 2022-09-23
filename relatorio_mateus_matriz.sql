CREATE ROLE user_mateus LOGIN ENCRYPTED PASSWORD 'md1235809eb3e34a27b734de7e9913a2dd0ecd9426b0d' NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;

CREATE schema if not exists mateus AUTHORIZATION user_mateus;

CREATE OR replace VIEW mateus.relatorio_matriz AS
    SELECT
        nf.nr_nota_fiscal,
        nf.nm_serie,
        nf.vl_nota_fiscal,
        u.cd_unidade,
        p.nm_razao_social AS nome_remetente,
        p2.nm_razao_social AS nome_destinatario,
        nf.nr_peso,
        nf.nr_peso_liquido,
        nfc.oid_conhecimento AS documento_transporte,
        c.vl_total_frete_calc AS valor_calculado,
        ct.numero AS numero_cte,
        c.vl_total_frete AS valor_realizado,
        e.numero AS numero_embarque,
        eo.oid_ocorrencia,
        o.descricao,
        (SELECT max(eo.dt_evento) FROM evento_ocorrencia eo WHERE eo.oid_nota_fiscal = nf.oid_nota_fiscal) AS ultima_ocorrencia,
        m.oid_motorista,
        e.placa,
        (SELECT array_to_string(array_agg(doc2.oid_ordem_coleta), ', ') FROM documento_ordem_coleta doc2 WHERE doc2.oid_nota_fiscal = nf.oid_nota_fiscal) AS ordem_coleta,
        c.oid_transportadora,
        nf.oid_produto,
        nf.situacao_sefaz,
        nf.dt_emissao as data_emissao_nf,
        (CASE
             WHEN c.dm_tipo_conhecimento = 0 THEN 'REDESPACHO'::text
             WHEN c.dm_tipo_conhecimento = 1 THEN 'NORMAL'::text
             WHEN c.dm_tipo_conhecimento = 2 THEN 'CORTESIA'::text
             WHEN c.dm_tipo_conhecimento = 3 THEN 'DEVOLUCAO'::text
             WHEN c.dm_tipo_conhecimento = 4 THEN 'REENTREGA'::text
             WHEN c.dm_tipo_conhecimento = 5 THEN 'EXPORTACAO'::text
             WHEN c.dm_tipo_conhecimento = 6 THEN 'REFATURAMENTO'::text
             WHEN c.dm_tipo_conhecimento = 7 THEN 'PALETIZACAO'::text
             WHEN c.dm_tipo_conhecimento = 8 THEN 'CARGA_FECHADA'::text
             WHEN c.dm_tipo_conhecimento = 9 THEN 'IMPORTACAO'::text
             WHEN c.dm_tipo_conhecimento = 10 THEN 'ICMS_ANTECIPADO'::text
             WHEN c.dm_tipo_conhecimento = 11 THEN 'REEMBOLSO'::text
             WHEN c.dm_tipo_conhecimento = 12 THEN 'ICMS_COMPLEMENTAR'::text
             WHEN c.dm_tipo_conhecimento = 13 THEN 'DESCARGA'::text
             WHEN c.dm_tipo_conhecimento = 14 THEN 'ESTADIA'::text
             WHEN c.dm_tipo_conhecimento = 15 THEN 'DIARIA'::text
             WHEN c.dm_tipo_conhecimento = 16 THEN 'COMPLEMENTAR'::text
             WHEN c.dm_tipo_conhecimento = 17 THEN 'VEICULO_ADICIONAL'::text
             WHEN c.dm_tipo_conhecimento = 18 THEN 'ESCOLTA'::text
             ELSE 'NOVO -'::text || c.dm_tipo_conhecimento
            END) AS tipo_conhecimento
    FROM nota_fiscal nf
             INNER JOIN unidade u on nf.oid_unidade = u.oid_unidade
             INNER JOIN pessoa p on p.oid_pessoa = nf.oid_remetente
             INNER JOIN pessoa p2 on p2.oid_pessoa = nf.oid_destinatario
             INNER JOIN nota_fiscal_conhecimento nfc on nf.oid_nota_fiscal = nfc.oid_nota_fiscal
             INNER JOIN conhecimento c on nfc.oid_conhecimento = c.oid_conhecimento
             LEFT JOIN cte ct on ct.oid_conhecimento = c.oid_conhecimento
             LEFT JOIN embarque e on c.oid_embarque = e.oid_embarque
             LEFT JOIN embarque_motorista em on e.oid_embarque = em.oid_embarque
             LEFT JOIN motorista m on em.oid_motorista = m.oid_motorista
             LEFT JOIN evento_ocorrencia eo on nf.oid_nota_fiscal = eo.oid_nota_fiscal
             LEFT JOIN ocorrencia o on eo.oid_ocorrencia = o.oid_ocorrencia
           left JOIN documento_ordem_coleta doc on doc.oid_nota_fiscal = nf.oid_nota_fiscal
    WHERE
            nf.oid_empresa = 1086 AND nf.dt_emissao::date >= (now() - interval '120 days')::date;

--Sem acesso as outras tabelas, nem para select
REVOKE ALL ON ALL functions IN SCHEMA public FROM user_mateus;
REVOKE ALL ON ALL sequences IN SCHEMA public FROM user_mateus;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM user_mateus;
--
REVOKE ALL ON ALL functions IN SCHEMA mateus FROM user_mateus;
REVOKE ALL ON ALL sequences IN SCHEMA mateus FROM user_mateus;
REVOKE ALL ON ALL TABLES IN SCHEMA mateus FROM user_mateus;

--altera dono do schema, não pode excluir
alter schema mateus owner to postgres;

--grant usage para não ter privilégios
grant usage on schema apodi to user_mateus;
grant usage on schema public to user_mateus;

--altera owner e apenas permissao de select para o user mateus
alter table mateus.relatorio_matriz  owner to postgres;
grant all on table mateus.relatorio_matriz to postgres;
grant select on table mateus.relatorio_matriz to user_mateus;