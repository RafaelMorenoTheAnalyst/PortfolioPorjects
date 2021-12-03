
--Selecting all data to get an idea of COVID Deaths dataset and the COVID Vaccination dataset
SELECT *
FROM CovidDeaths$
WHERE continent is null

SELECT *
FROM CovidVaccination$ 



--Shows the death percent from COVID in the United States
SELECT location, date, total_deaths, population, total_cases, (total_deaths/population)*100 as DeathPercent
FROM CovidDeaths$
WHERE continent is not null
and location like '%states%'
order by 1,2

--Percent of different country's population that has been infected by COVID
SELECT location, date, population, total_cases, (total_cases/population)*100 as PercentOfThePopulationInfected
FROM CovidDeaths$
order by 1,2


--Countries with the highest infection count compared to its population
SELECT location, population, MAX(total_cases), MAX(total_cases/population)*100 as PercentOfThePopulationInfected
FROM CovidDeaths$
group by location, population
order by PercentOfThePopulationInfected desc


--Countries with the highest death count compared to its population 
SELECT location, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM CovidDeaths$
WHERE continent is not null
group by location
order by TotalDeathCount desc


--Continents with the highest death count
SELECT continent, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM CovidDeaths$
WHERE continent is not null
group by continent
order by TotalDeathCount desc


--Global death percentage
SELECT SUM(new_cases) as TotalCases,SUM(CAST(new_deaths as int)),SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as DeathPercent
FROM CovidDeaths$
WHERE continent is not null


--Shows the percent of the population that has recieved at leaset one dose of the vaccine
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths$ dea
Join CovidVaccination$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


--CTE to perform a calculation to find a rolling percent of people vaccinated
WITH PopVsVac as (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidDeaths$ dea
Join CovidVaccination$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
Select *, (RollingPeopleVaccinated/Population)*100 as RollingPeopleVacinatedPercent
From PopvsVac


--Temp Tables to perform the same calculation done in the CTE example
--"drop table if exist" allows us to modify the table after it has been created

DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidDeaths$ dea
Join CovidVaccination$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated

--Creating view for creating visualizations later

--View for continent death count
CREATE VIEW ContinentTotalDeathCOunt as
SELECT continent, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM CovidDeaths$
WHERE continent is not null
group by continent

--View for rolling percent of people that have been vaccinated
CREATE VIEW PercentOfPeopleVaccinated as
WITH PopVsVac as (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidDeaths$ dea
Join CovidVaccination$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
Select *, (RollingPeopleVaccinated/Population)*100 as RollingPeopleVacinatedPercent
From PopvsVac

--View for countries and their percentage of the population that has been infected with COVID
CREATE VIEW CountriesInfectionPercent as
SELECT location, population, MAX(total_cases) as TotalCases, MAX(total_cases/population)*100 as PercentOfThePopulationInfected
FROM CovidDeaths$
group by location, population
--Death count by country
CREATE VIEW DeathCountByCountry as
SELECT location, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM CovidDeaths$
WHERE continent is not null
group by location
