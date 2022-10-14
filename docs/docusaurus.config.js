// @ts-check
// Note: type annotations allow type checking and IDEs autocompletion

const lightCodeTheme = require('prism-react-renderer/themes/vsLight');
const darkCodeTheme = require('prism-react-renderer/themes/vsDark');

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'Fluttium',
  tagline: 'The user flow testing tool for Flutter',
  url: 'https://fluttium.dev',
  baseUrl: '/',
  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',
  favicon: 'img/logo.svg',

  organizationName: 'wolfenrain',
  projectName: 'fluttium',

  // Even if you don't use internalization, you can use this field to set useful
  // metadata like html lang. For example, if your site is Chinese, you may want
  // to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          sidebarPath: require.resolve('./sidebars.js'),
          // Remove this to remove the "edit this page" links.
          editUrl: 'https://github.com/wolfenrain/docs/tree/main/docs/',
        },
        theme: {
          customCss: require.resolve('./src/css/custom.css'),
        },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      image: 'img/meta/open_graph.png',
      navbar: {
        title: 'Fluttium',
        logo: {
          alt: 'Fluttium Logo',
          src: 'img/logo.svg',
        },
        items: [
          {
            href: 'https://github.com/wolfenrain/fluttium',
            position: 'right',
            className: 'navbar-github-icon',
            'aria-label': 'GitHub repository',
          },
        ],
      },
      footer: {
        links: [
          {
            title: 'Docs',
            items: [
              {
                label: 'Why Fluttium',
                to: '/docs/why-fluttium',
              },
              {
                label: 'Getting Started',
                to: '/docs/getting-started',
              },
              {
                label: 'Fluttium CLI',
                to: '/docs/cli',
              },
              {
                label: 'Actions',
                to: '/docs/actions',
              },
            ],
          },
          {
            title: 'More',
            items: [
              {
                label: 'GitHub',
                href: 'https://github.com/wolfenrain/fluttium',
              },
              {
                label: 'Sponsor the Project',
                href: 'https://github.com/sponsors/wolfenrain',
              },
            ],
          },
        ],
      },
      prism: {
        additionalLanguages: ['bash', 'dart', 'yaml'],
        theme: lightCodeTheme,
        darkTheme: darkCodeTheme,
      },
    }),
};

module.exports = config;
