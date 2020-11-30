SELECT
  tenders.id,
  title,
  document_number,
  permalink,
  contract_statuses.text AS status,
  CASE process_types.text
    WHEN 'Contrato menor' THEN true
    ELSE false
  END as minor_contract,
  contract_types.text AS contract_type,
  submission_date,
  open_proposals_date,
  number_of_batches,
  number_of_proposals,
  contractors.name AS contractor,
  contractors_types.text AS contractor_type,
  contract_value,
  initial_amount,
  initial_amount_no_taxes,
  array_to_string(tenders.cpvs, ',') AS cpvs,
  process_types.text AS process_type
FROM
  tenders
  LEFT JOIN fiscal_entities contractors ON contractor_id = contractors.id
  LEFT JOIN entity_types contractors_types ON contractors_types.id = contractors.entity_type
  LEFT JOIN contract_types ON contract_type = contract_types.id
  LEFT JOIN contract_statuses ON status = contract_statuses.id
  LEFT JOIN process_types ON tenders.process_type = process_types.id
WHERE contractors.custom_place_id = 08211
