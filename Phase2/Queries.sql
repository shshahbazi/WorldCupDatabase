create table team
(
    id varchar(10),
    name varchar(30),
    nationality varchar(20),
    group_number varchar(3),
    primary key (id)
);

create table human
(
    ID          varchar(10),
    name        varchar(50),
    nationality varchar(20),
    age         int,
    primary key (ID)
);

create table player
(
    id      varchar(10) references human,
    team_id varchar(10),
    number  int,
    goal    int,
    primary key (id),
    foreign key (team_id) references team(id)
);

create table referee
(
    id varchar(10) references human,
    type varchar(20),
    primary key (id)
);

create table coach
(
    id varchar(10) references human,
    team_id varchar(10),
    primary key (id),
    foreign key (team_id) references team(id)
);
create table referee_team
(
    id varchar(10),
    head_id varchar(10),
    assistant1_id varchar(10),
    assistant2_id varchar(10),
    fourth_id varchar(10),
    var_id varchar(10),
    primary key (id),
    foreign key (head_id) references referee(id),
    foreign key (assistant1_id) references referee(id),
    foreign key (assistant2_id) references referee(id),
    foreign key (fourth_id) references referee(id),
    foreign key (var_id) references referee(id)
);

create table stadium
(
    id varchar(10),
    name varchar(30),
    create_date date,
    stadium_capacity int,
    city varchar(30),
    is_covered_stadium bit,
    primary key (id)
);

create table match_table
(
    id varchar(10),
    team1_id varchar(10) references team,
    team2_id varchar(10) references team,
    team1_goals int,
    team2_goals int,
    stage varchar(30),
    referee_team_id varchar(10),
    best_player_id varchar(10),
    stadium_id varchar(10),
    primary key (id),
    foreign key (referee_team_id) references referee_team(id),
    foreign key (best_player_id) references player(id),
    foreign key (stadium_id) references stadium(id)
);

create table goal
(
    match_id varchar(10),
    player_id varchar(10),
    minute int,
    is_penalty bit,
    primary key (match_id,player_id,minute),
    foreign key (match_id) references match_table(id),
    foreign key (player_id) references player(id)
);

create table substitute
(
    match_id varchar(10),
    player_id_in varchar(10),
    player_id_out varchar(10) references player,
    minute int,
    type varchar(20),
    is_mandatory bit,
    primary key (match_id, player_id_out),
    foreign key (match_id) references match_table(id),
    foreign key (player_id_in) references player(id)
);

create table card
(
    match_id varchar(10),
    player_id varchar(10),
    minute int,
    color varchar(10),
    primary key (match_id,player_id,minute),
    foreign key(match_id) references match_table(id),
    foreign key (player_id) references player(id)
);

--Queries

--1.آقای گل مسابقات در این دوره جام جهانی چه کسی شده است
SELECT P.id, COUNT(*)
FROM player AS p
	  JOIN goal AS g
	  ON p.id = g.player_id
GROUP BY P.id
HAVING COUNT(*) = (SELECT MAX(goals)
				   FROM (SELECT p.id, COUNT(p.id) AS goals
						 FROM player AS p
							  JOIN goal AS g
							  ON p.id = g.player_id
						 GROUP BY(p.id)) AS temp);
--2.کدامیک از داوران این دوره تعداد بیشتری بازی سوت زده است
SELECT referee.id, COUNT(*)
FROM referee JOIN referee_team ON referee.id = referee_team.assistant1_id
								  OR referee.id = referee_team.assistant2_id
								  OR referee.id = referee_team.fourth_id
								  OR referee.id = referee_team.head_id
								  OR referee.id = referee_team.var_id
								  JOIN match_table ON (referee_team.id = match_table.referee_team_id)
GROUP BY referee.id
HAVING COUNT(*) = (SELECT MAX(match_count)
				   FROM (SELECT referee.id, COUNT(*) AS match_count
						 FROM referee JOIN referee_team ON referee.id = referee_team.assistant1_id
								  OR referee.id = referee_team.assistant2_id
								  OR referee.id = referee_team.fourth_id
								  OR referee.id = referee_team.head_id
								  OR referee.id = referee_team.var_id
								  JOIN match_table ON (referee_team.id = match_table.referee_team_id)
						 GROUP BY referee.id) AS referee_match_count);
--3.نام بازیکنانی که از دقیقه 80 به بعد گل زده اند
SELECT p.id,h.name
FROM player AS p
JOIN goal AS g
ON p.id = g.player_id
JOIN human AS h
ON h.id = p.id
WHERE g.minute >= 80
GROUP BY p.id, h.name
--4.در کدام استادیوم قطر تعداد پنالتی منجر به گل کمتری ثبت شده است
SELECT s.id AS id, s.name AS name, COUNT(g.is_penalty) AS accepted_penalties
FROM goal g
JOIN match_table m
ON m.id = g.match_id
JOIN stadium s
ON s.id = m.stadium_id
WHERE g.is_penalty = 1
GROUP BY s.id, s.name
HAVING COUNT(g.is_penalty) = (SELECT MIN(penalties)
							  FROM (SELECT s.id, COUNT(*) AS penalties
									FROM goal g
									JOIN match_table m
									ON m.id = g.match_id
									JOIN stadium s
									ON s.id = m.stadium_id
									WHERE g.is_penalty = 1
									GROUP BY s.id, s.name) AS stadium_penalties);
--5.نام مسن ترین بازیکنی که در این دوره گلزنی کرده است
SELECT player.id ,h.name, MAX(h.age)
FROM human AS h JOIN player ON (h.ID = player.id)
WHERE player.id IN (SELECT goal.player_id
					FROM player JOIN goal ON (player.id = goal.player_id));
--6.در مسابقات جام جهانی در چند مسابقه کمتر از 5 تعویض انجام شده است
SELECT COUNT(*) 
FROM (SELECT COUNT(*) AS substitude_number
	  FROM match_table m
	  JOIN substitute s
	  ON m.id = s.match_id
	  GROUP BY(m.id)
	  HAVING COUNT(*) < 5) AS temp;
--7.نام و ظرفیت ورزشگاههایی که دو تیم آرژانتین یا فرانسه در آنها بازی کردهاند را نام ببرید)به غیر
--از مراحل گروهی(
SELECT s.name, s.stadium_capacity
FROM match_table m
JOIN stadium s
ON s.id = m.stadium_id
WHERE (m.team1_id IN ('T-28', 'T-03') OR
	  m.team2_id IN ('T-28', 'T-03')) AND
      m.stage <> 'group stage';
--8.در چه بازیهایی تعداد گلی که در نیمه اول به ثمر رسیده است، بیشتر از تعداد گلهای نیمه
--دوم است
WITH first_half(match_id,number_of_goals) AS
				(SELECT match_id, COUNT(g.match_id) as number_of_goals
				FROM goal g
				JOIN match_table m
				ON g.match_id = m.id
				WHERE g.minute <= 45
                GROUP BY(g.match_id)),
second_half(match_id,number_of_goals) AS
			(SELECT match_id, COUNT(g.match_id) as number_of_goals  
		     FROM goal g
		     JOIN match_table m
		     ON g.match_id = m.id
		     WHERE g.minute > 45
			 GROUP BY(g.match_id))
SELECT fh.match_id, fh.number_of_goals AS 'goals in first half', sh.number_of_goals AS 'goals in second half'
FROM first_half fh
JOIN second_half sh
ON fh.match_id = sh.match_id
WHERE fh.number_of_goals > sh.number_of_goals;
--9.میانگین تعداد گلی که هر تیم در مسابقات به ثمر رسانده است را به ترتیب نمایش دهید
SELECT temp.id, AVG(temp.goals) AS average
FROM (SELECT m.team1_id AS id, COUNT(m.team1_id) AS goals
	  FROM match_table m
	  GROUP BY(m.team1_id)
	  UNION
	  SELECT m.team2_id AS id, COUNT(m.team2_id) AS goals
	  FROM match_table m
	  GROUP BY(m.team2_id))AS temp
GROUP BY(temp.id)
ORDER BY(average);
--10هریک از داوران شرکت کننده در این دوره چند پنالتی منجر به گل گرفته اند.
SELECT all_referees.r_id, h.name, COUNT(all_referees.r_id) AS 'penalty lent to goal'
FROM (SELECT rt.id AS rt_id, r.id AS r_id
		FROM referee r
		JOIN referee_team rt
		ON r.id = rt.head_id
		UNION
		SELECT rt.id AS rt_id, r.id AS r_id
		FROM referee r
		JOIN referee_team rt
		ON r.id = rt.assistant1_id
		UNION
		SELECT rt.id AS rt_id, r.id AS r_id
		FROM referee r
		JOIN referee_team rt
		ON r.id = rt.assistant2_id
		UNION
		SELECT rt.id AS rt_id, r.id AS r_id
		FROM referee r
		JOIN referee_team rt
		ON r.id = rt.var_id
		UNION
		SELECT rt.id AS rt_id, r.id AS r_id
		FROM referee r
		JOIN referee_team rt
		ON r.id = rt.fourth_id) AS all_referees
JOIN match_table m
ON m.referee_team_id = all_referees.rt_id
JOIN goal g
ON m.id = g.match_id
JOIN human h
ON h.ID = all_referees.r_id
WHERE g.is_penalty = 1
GROUP BY all_referees.r_id, h.name;
--11.نام تیم هایی که از سرمربی بومی استفاده کرده اند
SELECT coach.id, team.name, human.name
FROM team JOIN coach ON (team.id = coach.team_id) JOIN human ON (coach.id = human.ID)
WHERE team.nationality = human.nationality;
--12.نام بازیکنی که رکورددار دریافت جایزه بهترین بازیکن زمین است
SELECT player.id, human.name, COUNT(*)
FROM human JOIN player ON (human.ID = player.id) JOIN match_table ON (match_table.Best_Player_id = player.id)
GROUP BY player.id, human.name
HAVING COUNT(*) = (SELECT MAX(count_best_award)
				   FROM (SELECT player.id, COUNT(*)as count_best_award
						 FROM human JOIN player ON (human.ID = player.id) JOIN match_table ON (match_table.Best_Player_id = player.id)
						 GROUP BY player.id) AS count_awards);
--13.نام مربیانی که تیم آنها از مرحله گروهی صعود نکرده است
SELECT human.name AS coach_name, team.name AS team_name
FROM team JOIN coach ON (team.id = coach.team_id) JOIN human ON (coach.id = human.id)
WHERE team.id NOT IN (SELECT match_table.team1_id
						FROM match_table JOIN team ON match_table.team1_id = team.id
						WHERE match_table.stage = 'round of 16')
AND team.id NOT IN (SELECT match_table.team2_id
						FROM match_table JOIN team ON match_table.team2_id=team.id
						WHERE match_table.stage = 'round of 16');
--14.کدام تیم رکورددار دریافت بیشترین تعداد کارت )زرد و قرمز ( در این دوره است
SELECT team.id, COUNT(*)
FROM player JOIN card ON (player.id = card.player_id) JOIN team ON (player.team_id = team.id)
GROUP BY team.id
HAVING COUNT(*) = (SELECT MAX(card_count)
				   FROM(SELECT team.id, COUNT(*) AS card_count
						FROM player JOIN card ON (player.id = card.player_id) JOIN team ON (player.team_id = team.id)
						GROUP BY team.id) AS team_cards);
--15.نام بازیکنانی تعویضی که پس از ورود به زمین موفق به گلزنی شده اند
SELECT player.id, human.name 
FROM player JOIN human ON (player.id = human.id) JOIN substitute ON (player.id = substitute.player_id_in) JOIN goal ON (player.id = goal.player_id)
WHERE goal.minute >= substitute.minute;
--16.نام تیم هایی که در یک بازی با وجود دریافت کارت قرمز برنده بازی نیز شده اند
WITH winner(winner_id, id) AS (SELECT m.team1_id AS winner_id, m.id
           FROM match_table m
           WHERE m.team1_goals > m.team2_goals
           UNION
           SELECT m.team2_id AS winner_id, m.id
           FROM match_table m
           WHERE m.team2_goals > m.team1_goals)
SELECT team.id, team.name
FROM player JOIN team ON(player.team_id = team.id) JOIN winner w ON team.id= w.winner_id
JOIN match_table m
ON (m.team1_id = team.id OR m.team2_id = team.id) AND w.id = m.id
JOIN card c  
ON c.match_id = m.id AND c.player_id = player.id
WHERE c.color = 'red'
--17.نام و ملیت مربیان غیربومی که تیم ملی کشور خودشان در جام حضود دارد را نام ببرید.
SELECT coach.id AS coach_id, team.name AS team_name, human.name AS coach_name
FROM team JOIN coach ON (team.id = coach.team_id) JOIN human ON (coach.id = human.ID)
WHERE team.nationality <> human.nationality 
AND human.nationality IN (SELECT team.nationality
						  FROM team);