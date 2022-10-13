import React from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import { useColorMode } from '@docusaurus/theme-common';

import styles from './index.module.css';

function HomepageHeader() {
  const { siteConfig } = useDocusaurusContext();
  return (
    <header className={clsx('hero', styles.heroBanner)}>
      <div className="container">
        <h1 className="hero__title">{siteConfig.title}</h1>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <HomepageHeroImage />
        <HomepageCTA />
      </div>
    </header>
  );
}

export default function Home(): JSX.Element {
  const { siteConfig } = useDocusaurusContext();
  return (
    <Layout
      description={`The official site for ${siteConfig.title}. ${siteConfig.tagline}.`}
    >
      <HomepageHeader />
      <main>
        <HomepageFeatures />
      </main>
    </Layout>
  );
}

function HomepageCTA() {
  return (
    <div className={styles.width}>
      <Link
        className="button button--primary button--lg"
        to="/docs/getting-started"
      >
        Get Started
      </Link>
      <Link
        className="button button--secondary button--lg"
        to="/docs/action-references"
      >
        Learn More
      </Link>
    </div>
  );
}

function HomepageHeroImage() {
  const { colorMode } = useColorMode();
  return (
    <img
      className={clsx(styles.heroImage)}
      src={colorMode == 'dark' ? 'img/hero.gif' : 'img/hero.gif'}
      alt="Hero"
      style={{
        borderRadius: 'var(--ifm-button-border-radius)',
        margin: '2em 0',
      }}
    />
  );
}

type FeatureItem = {
  title: string;
  description: JSX.Element;
};

const FeatureList: FeatureItem[] = [
  {
    title: 'Fast Iteration',
    description: (
      <>
        Fluttium is able to monitor both your test file and your app code, so
        you can see your changes reflected in your tests immediately.
      </>
    ),
  },
  {
    title: 'Powerful Declarative Syntax',
    description: (
      <>
        Fluttium's syntax is designed to be as declarative as possible, allowing
        you to write tests that are easy to read and understand. Inspired by
        frameworks like <a href="https://maestro.mobile.dev">Maestro</a>.
      </>
    ),
  },
  {
    title: 'Cross-platform',
    description: (
      <>
        Fluttium is built on top of <a href="https://flutter.dev/">Flutter</a>,
        so it can run on any platform that Flutter supports and is able to
        automatically wait until an action is completed.
      </>
    ),
  },
];

function Feature({ title, description }: FeatureItem) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center padding-horiz--md">
        <h3>{title}</h3>
        <p>{description}</p>
      </div>
    </div>
  );
}

function HomepageFeatures(): JSX.Element {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
