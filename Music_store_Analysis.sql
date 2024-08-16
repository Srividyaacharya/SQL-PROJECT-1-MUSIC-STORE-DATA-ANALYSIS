--DATABASE CREATION---

Create Database Music_DB

--To Query database---
Use Music_DB

--View All the records in table--
select * from employee

--1. Who is the senior most employee based on job title?---

SELECT
	TOP 1
    employee_id,
    first_name,
    last_name,
    title,
    levels,
    address,
    city
FROM 
    employee
ORDER BY 
    levels DESC

--2. Which countries have the most Invoices?--

SELECT 
    billing_country,
    COUNT(*) AS No_of_Invoices
FROM 
    invoice
GROUP BY 
    billing_country
ORDER BY 
    No_of_Invoices DESC;

--3. What are top 3 values of total invoice?--

SELECT
	TOP 3
    total,
	invoice_id,
	customer_id   
FROM 
    invoice
ORDER BY 
    total DESC

/* 4. Which city has the best customers? We would like to throw a promotional Music 
Festival in the city we made the most money. Write a query that returns one city that 
has the highest sum of invoice totals. Return both the city name & sum of all invoice 
totals*/

SELECT 
    billing_city,
    SUM(total) AS 'Invoice Total'
FROM 
    invoice
GROUP BY 
    billing_city
ORDER BY 
    'Invoice Total' DESC;


/* 5. Who is the best customer? The customer who has spent the most money will be 
declared the best customer. Write a query that returns the person who has spent the 
most money */ 

SELECT
	TOP 1
    customer.first_name,
    customer.last_name,
    customer.customer_id,
    SUM(invoice.total) AS Total_invoice
FROM 
    customer
JOIN 
    invoice ON customer.customer_id = invoice.customer_id
GROUP BY 
    customer.customer_id,
    customer.first_name,
    customer.last_name
ORDER BY 
    Total_invoice DESC
/*
6. Write query to return the email, first name, last name, & Genre of all Rock Music 
listeners. Return your list ordered alphabetically by email starting with A
*/

SELECT DISTINCT
    customer.email,
    customer.first_name,
    customer.last_name
FROM
    customer
JOIN
    invoice ON customer.customer_id = invoice.customer_id
JOIN
    invoice_line ON invoice.invoice_id = invoice_line.invoice_id
JOIN
    track ON invoice_line.track_id = track.track_id
JOIN
    genre ON track.genre_id = genre.genre_id
WHERE
    genre.name LIKE 'ROCK'
ORDER BY
    customer.email;


/*7.7. Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands
*/

SELECT 
	TOP 10
    a.artist_id,
    a.name,
    COUNT(t.track_id) AS Total_Track_Count
FROM 
    track t
JOIN 
    album al ON t.album_id = al.album_id
JOIN 
    artist a ON a.artist_id = al.artist_id
JOIN 
    genre g ON g.genre_id = t.genre_id
WHERE 
    g.name = 'ROCK'
GROUP BY 
    a.artist_id,
    a.name
ORDER BY 
    Total_Track_Count DESC;
/*
8.	Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. 
Order by the song length with the longest songs listed first
*/

SELECT 
    name,
    milliseconds
FROM 
    track
WHERE 
    milliseconds > (SELECT AVG(milliseconds) FROM track)
ORDER BY 
    milliseconds DESC;

/*9.	Find how much amount spent by each customer on artists? 
Write a query to return customer name, artist name and total spent
*/

WITH best_selling_artist AS (
		SELECT TOP 1 
		artist.artist_id as 'artist id', 
		artist.name as 'artist name',
		SUM(invoice_line.unit_price*invoice_line.quantity) AS 'total_sales'
		FROM invoice_line
		JOIN track ON track.track_id = invoice_line.track_id
		JOIN album ON album.album_id = track.album_id
		JOIN artist ON artist.artist_id = album.artist_id
		GROUP BY artist.artist_id, artist.name
		ORDER BY 3 DESC )
SELECT 
	customer.customer_id,
	customer.first_name,
	customer.last_name,
	SUM(invoice_line.unit_price*invoice_line.quantity) AS 'amount_spent',
	best_selling_artist.[artist name]
	FROM invoice 
	JOIN customer ON customer.customer_id =invoice.customer_id
	JOIN invoice_line ON invoice_line.invoice_id = invoice.invoice_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN album ON album.album_id = track.album_id
	JOIN best_selling_artist ON best_selling_artist.[artist id] = album.artist_id
	GROUP BY customer.customer_id,customer.first_name,customer.last_name,best_selling_artist.[artist name]
	ORDER BY [amount_spent] DESC


/*We want to find out the most popular music Genre for each country. 
We determine the most popular genre as the genre with the highest amount of purchases. 
Write a query that returns each country along with the top Genre. 
For countries where the maximum number of purchases is shared return all Genres*/


WITH popular_genre AS (
    SELECT COUNT(invoice_line.quantity) AS purchases,
        customer.country,
        genre.name AS genre_name,
        genre.genre_id,
        ROW_NUMBER() OVER 
		(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) 
		AS row_num
    FROM 
    invoice_line
    JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
    JOIN customer ON customer.customer_id = invoice.customer_id
    JOIN track ON track.track_id = invoice_line.track_id
    JOIN genre ON genre.genre_id = track.genre_id
    GROUP BY 
        customer.country, genre.name, genre.genre_id
)
SELECT purchases,country,genre_name
FROM 
    popular_genre
WHERE 
    row_num = 1;

/*11Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount*/

with customer_with_country as
(
select customer.customer_id,first_name,last_name,billing_country,sum(total) as 'total spending',
row_number() over (partition by billing_country order by sum(total) desc) as RowNo
from invoice
join customer on customer.customer_id = invoice.customer_id
group by customer.customer_id,first_name,last_name,billing_country
)

select *  from customer_with_country where rowNo =1

--12.Retrieve the most expensive track for each genre---

SELECT g.Name AS GenreName, t.Name AS TrackName, MAX(t.unit_price) AS MaxPrice
FROM track t
JOIN genre g ON t.Genre_Id = g.Genre_Id
GROUP BY g.Name, t.Name;

--13.List all playlists and the number of tracks in each playlist.--

SELECT pl.Name AS PlaylistName, COUNT(plt.Track_Id) AS NumberOfTracks
FROM playlist pl
LEFT JOIN playlist_track plt ON pl.Playlist_Id = plt.Playlist_Id
GROUP BY pl.Name order by NumberOfTracks DESC

--14 Find the average price of tracks in each album --

SELECT a.Title AS AlbumTitle, AVG(t.Unit_Price) AS AveragePrice
FROM album a
JOIN track t ON a.album_id = t.Album_Id
GROUP BY a.Title

---15. Find the top 3 most recent invoices and their total sales

SELECT TOP 3 i.invoice_id, i.Invoice_Date, SUM(il.Unit_Price * il.Quantity) AS TotalSales
FROM invoice i
JOIN invoice_line il ON i.Invoice_Id = il.Invoice_Id
GROUP BY i.Invoice_Id, i.Invoice_Date
ORDER BY i.Invoice_Date DESC

--16 Get the genre with the highest total sales.--

SELECT TOP 1 g.Name AS GenreName
FROM genre g
JOIN track t ON g.Genre_Id = t.Genre_Id
JOIN invoice_line il ON t.Track_Id = il.Track_Id
GROUP BY g.Name
ORDER BY SUM(il.Unit_Price * il.Quantity) DESC

--17 Retrieve the list of tracks and their composers with no sales--

SELECT t.Name AS TrackName, t.Composer
FROM track t
LEFT JOIN invoice_line il ON t.Track_Id = il.Track_Id
WHERE il.Track_Id IS NULL

--18 .Find all customers who have purchased tracks from a specific genre -- 

SELECT DISTINCT c.First_Name, c.Last_Name
FROM customer c
JOIN invoice i ON c.Customer_Id = i.Customer_Id
JOIN invoice_line il ON i.Invoice_Id = il.Invoice_Id
JOIN track t ON il.Track_Id = t.Track_Id
WHERE t.Genre_Id = (SELECT Genre_Id FROM genre WHERE Name = 'Jazz')

--19 Show the total number of tracks and their total sales in each genre --

SELECT g.Name AS GenreName, COUNT(t.Track_Id) AS TotalTracks, SUM(il.Unit_Price * il.quantity) AS TotalSales
FROM genre g
JOIN track t ON g.Genre_Id = t.Genre_Id
LEFT JOIN invoice_line il ON t.Track_Id = il.Track_Id
GROUP BY g.Name;

--20 Find the most recent invoice for each customer ---

SELECT c.First_Name, c.Last_Name, MAX(i.Invoice_Date) AS MostRecentInvoiceDate
FROM customer c
JOIN invoice i ON c.Customer_Id = i.Customer_Id
GROUP BY c.Customer_Id,c.First_Name, c.Last_Name

