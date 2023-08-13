select * from PortfolioProject..CovidDeaths
where continent is not null	
order by 3,4

--select * from PortfolioProject..CovidVaccination
--order by 3,4

select Location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
where continent is not null
order by 1,2

-- Total cases vs total Deaths
-- Shows the likelihood of dying if you contract covid in your country
select Location, date, total_cases, total_deaths, (Convert (Decimal(15, 3), total_deaths)/Convert (Decimal(15, 3),total_cases)*100) as DeathPercent
from PortfolioProject..CovidDeaths
where location like '%states%'
and continent is not null
order by 1,2

-- Total Cases vs Population
-- Shows the percentage of population got Covid
select Location, date, population, total_cases, (Convert (Decimal(15, 3), total_cases)/Convert (Decimal(15, 3),population)*100) as CovidPercent
from PortfolioProject..CovidDeaths
order by 1,2

-- Countries with highest infection rate compared to population
select Location, population, max(total_cases) as HighestInfectionCount, max((Convert (Decimal(15, 3), total_cases)/Convert (Decimal(15, 3),population)) *100) as CovidPercent
from PortfolioProject..CovidDeaths
where continent is not null
group by location, population
order by CovidPercent desc

-- BREAKING DOWN BY CONTINENT
-- Continents with highest death count per population

select continent, max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc

--Global

select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100
from PortfolioProject..CovidDeaths
where continent is not null
order by 1,2

select date, sum(new_cases) as total_cases, sum(cast(nullif(new_deaths,0) as int)) as total_deaths, sum(cast(nullif(new_deaths,0) as int))/sum(nullif(new_cases,0))*100 as DeathPercent
from PortfolioProject..CovidDeaths
where continent is not null
group by date
order by 1,2

--Total population vs Vaccination

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccination vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

--CTE

with popvsvac (continet, location, date, population, new_vaccinations, RollingVacinations)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date ROWS UNBOUNDED PRECEDING) as RollingVaccinations
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccination vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
select * , (RollingVacinations/population)*100
from popvsvac


--TEMP TABLE

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date ROWS UNBOUNDED PRECEDING) as RollingVaccinations
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccination vac
	on dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null


Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- View to store data for visulizations

Create View PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date ROWS UNBOUNDED PRECEDING) as RollingVaccinations
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccination vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
