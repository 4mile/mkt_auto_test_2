view: k_means_create_model {
  derived_table: {
    persist_for: "1 second"

    create_process: {

      sql_step: CREATE OR REPLACE MODEL looker_pdts.{% parameter model_name.select_model_name %}
                  OPTIONS(MODEL_TYPE = 'KMEANS'
                  {% if choose_number_of_clusters._parameter_value == 'auto' %}
                  {% else %}
                  , NUM_CLUSTERS = {% parameter choose_number_of_clusters %}
                  {% endif %}
                  , KMEANS_INIT_METHOD = 'KMEANS++'
                  , STANDARDIZE_FEATURES = TRUE)
                  AS (SELECT * EXCEPT(item_id)
                      FROM looker_pdts.{% parameter model_name.select_model_name %}_training_data)
      ;;

        sql_step: CREATE TABLE IF NOT EXISTS looker_pdts.BQML_K_MEANS_MODEL_INFO
                  (model_name STRING,
                  number_of_clusters STRING,
                  item_id STRING,
                  features STRING,
                  created_at TIMESTAMP)
      ;;

          sql_step: INSERT INTO looker_pdts.BQML_K_MEANS_MODEL_INFO
                (model_name,
                number_of_clusters,
                item_id,
                features,
                created_at)

                SELECT '{% parameter model_name.select_model_name %}' AS model_name,
                  '{% parameter choose_number_of_clusters %}' AS number_of_clusters,
                  {% assign item_id = _filters['k_means_training_data.select_item_id'] | sql_quote | replace: '"','' | remove: "'" %}
                    '{{ item_id }}' AS item_id,
                  {% assign features = _filters['k_means_training_data.select_features'] | sql_quote | replace: '"','' | remove: "'" %}
                    '{{ features }}' AS features,
                  CURRENT_TIMESTAMP AS created_at
      ;;
        }
      }

      parameter: choose_number_of_clusters {
        view_label: "3. Choose Model Parameters"
        label: "Select Number of Clusters (optional)"
        description: "Enter the number of clusters you want to create"
        type: number
        default_value: "auto"
      }

      dimension: status {
        view_label: "4. Create Model"
        label: "Build Status (REQUIRED)"
        description: "Selecting this field is required to start building your model"
        type: string
        sql: 'Complete' ;;
      }
    }
