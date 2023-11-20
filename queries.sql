/* Query 1 - query used for the first insight */
WITH animation_films_df AS (
  SELECT film.film_id 
    FROM category 
      JOIN film_category 
        ON category.name = 'Animation' AND 
           category.category_id = film_category.category_id
      JOIN film 
        ON film.film_id = film_category.film_id
), rental_count_per_month_df AS (
  SELECT DATE(DATE_TRUNC('month', rental.rental_date)) AS month,
         COUNT(rental.rental_id) AS rental_count
    FROM animation_films_df AS film
      JOIN inventory 
        ON inventory.film_id = film.film_id
      JOIN rental 
        ON rental.inventory_id  = inventory.inventory_id
  GROUP BY month
  ORDER BY month
), final_result AS (
  SELECT to_char(month, 'YYYY-MM') AS month,
         rental_count
    FROM rental_count_per_month_df
)

SELECT * 
  FROM final_result;

/* Query 2 - query used for the second insight */
WITH rental_inventory_df AS (
  SELECT inventory.store_id,
         DATE_TRUNC('month', rental.rental_date) AS rental_month
    FROM inventory 
      JOIN rental 
        ON inventory.inventory_id = rental.inventory_id
), final_result AS (
  SELECT store_id,
         to_char(rental_month, 'YYYY-MM') AS rental_month,
         COUNT(*) AS count_rentals
    FROM rental_inventory_df
  GROUP BY store_id, rental_month
  ORDER BY store_id, rental_month
)

SELECT * 
  FROM final_result;

/* Query 3 - query used for the third insight */
WITH film_duration_length_categories AS (
  SELECT category.name,
         NTILE(4) OVER (ORDER BY film.rental_duration) AS standard_quartile
    FROM category 
      JOIN film_category 
        ON category.name = 'Animation' AND 
           category.category_id = film_category.category_id
      JOIN film 
        ON film.film_id = film_category.film_id 
)

SELECT standard_quartile,
       COUNT(*) AS films_count
  FROM film_duration_length_categories
GROUP BY standard_quartile
ORDER BY standard_quartile, films_count;

/* Query 4 - query used for the forth insight */
WITH top_paying_customers AS (
  SELECT customer_id,
         SUM(payment.amount) AS total_amount
     FROM payment
  GROUP BY customer_id
  ORDER BY total_amount DESC
  LIMIT 2
), customer_peymants_aggregated AS (
   SELECT DATE_TRUNC('month', payment.payment_date) AS payment_mon,
          CONCAT(customer.first_name,' ', customer.last_name) AS fullname, 
          SUM(payment.amount) AS pay_amount
     FROM customer
       JOIN payment
         ON DATE_PART('year', payment.payment_date) = '2007' AND
            customer.customer_id IN (SELECT customer_id FROM top_paying_customers ) AND
            customer.customer_id = payment.customer_id
  GROUP BY fullname, payment_mon
  ORDER BY fullname, payment_mon
), final_result AS (
  SELECT fullname,
		 to_char(payment_mon, 'YYYY-MM') AS payment_mon,
		 pay_amount
    FROM customer_peymants_aggregated
)

SELECT * 
  FROM final_result;