import 'package:book_hive/models/book.dart';
import 'package:book_hive/models/book_details.dart';
import 'package:book_hive/models/user.dart';

final List<Book> fakeBooks = [
  Book(
    isbn: "9780131103627",
    title: "The C Programming Language",
    summary:
        "A classic book that teaches the C programming language and system-level programming concepts.",
    genre: "Programming",
    language: "English",
    author: "Brian W. Kernighan, Dennis M. Ritchie",
    publisher: "Prentice Hall",
    publishedYear: 1988,
    coverUrl:
        "https://images.unsplash.com/photo-1524995997946-a1c2e315a42f?auto=format&fit=crop&w=400&q=80",
  ),
  Book(
    isbn: "9780132350884",
    title: "Clean Code",
    summary:
        "A handbook of agile software craftsmanship focusing on writing readable and maintainable code.",
    genre: "Software Engineering",
    language: "English",
    author: "Robert C. Martin",
    publisher: "Prentice Hall",
    publishedYear: 2008,
    coverUrl:
        "https://images.unsplash.com/photo-1523475472560-d2df97ec485c?auto=format&fit=crop&w=400&q=80",
  ),
  Book(
    isbn: "9780262033848",
    title: "Introduction to Algorithms",
    summary:
        "Comprehensive coverage of modern algorithms with rigorous analysis.",
    genre: "Computer Science",
    language: "English",
    author: "Thomas H. Cormen et al.",
    publisher: "MIT Press",
    publishedYear: 2009,
    coverUrl:
        "https://images.unsplash.com/photo-1461749280684-dccba630e2f6?auto=format&fit=crop&w=400&q=80",
  ),
  Book(
    isbn: "9780134685991",
    title: "Effective Java",
    summary: "Best practices for writing robust, maintainable Java code.",
    genre: "Programming",
    language: "English",
    author: "Joshua Bloch",
    publisher: "Addison-Wesley",
    publishedYear: 2018,
    coverUrl:
        "https://images.unsplash.com/photo-1455884981818-54cb785db6fc?auto=format&fit=crop&w=400&q=80",
  ),
  Book(
    isbn: "9780596007126",
    title: "Head First Design Patterns",
    summary:
        "A visually rich guide to design patterns using engaging examples.",
    genre: "Software Design",
    language: "English",
    author: "Eric Freeman, Elisabeth Robson",
    publisher: "O'Reilly Media",
    publishedYear: 2004,
    coverUrl:
        "https://images.unsplash.com/photo-1496104679561-38b3b4d7a4d0?auto=format&fit=crop&w=400&q=80",
  ),
  Book(
    isbn: "9789849036343",
    title: "Pather Panchali",
    summary:
        "A poignant novel portraying rural Bengali life and human struggle.",
    genre: "Fiction",
    language: "Bengali",
    author: "Bibhutibhushan Bandyopadhyay",
    publisher: "Signet Press",
    publishedYear: 1929,
    coverUrl:
        "https://images.unsplash.com/photo-1463320726281-696a485928c7?auto=format&fit=crop&w=400&q=80",
  ),
  Book(
    isbn: "9789849023459",
    title: "Ami Topu",
    summary:
        "A collection of imaginative and philosophical stories for young readers.",
    genre: "Children's Literature",
    language: "Bengali",
    author: "Humayun Ahmed",
    publisher: "Ananya",
    publishedYear: 1995,
    coverUrl:
        "https://images.unsplash.com/photo-1495446815901-a7297e633e8d?auto=format&fit=crop&w=400&q=80",
  ),
  Book(
    isbn: "9780439139601",
    title: "Harry Potter and the Goblet of Fire",
    summary:
        "Harry competes in the Triwizard Tournament during his fourth year at Hogwarts.",
    genre: "Fantasy",
    language: "English",
    author: "J.K. Rowling",
    publisher: "Bloomsbury",
    publishedYear: 2000,
    coverUrl:
        "https://images.unsplash.com/photo-1507842217343-583bb7270b66?auto=format&fit=crop&w=400&q=80",
  ),
];

final List<BookDetails> fakeBookDetails = [
  BookDetails(
    isbn: "9780131103627",
    edition: "2nd Edition",
    pdfLink: "https://pdfobject.com/pdf/sample.pdf",
    audioUrl:
        "https://www.learningcontainer.com/wp-content/uploads/2020/02/Kalimba.mp3",
  ),
  BookDetails(
    isbn: "9780132350884",
    edition: "1st Edition",
    pdfLink: "https://pdfobject.com/pdf/sample.pdf",
    audioUrl: "https://example.com/audio/clean-code-1e.mp3",
  ),
  BookDetails(
    isbn: "9780262033848",
    edition: "3rd Edition",
    pdfLink: "https://pdfobject.com/pdf/sample.pdf",
    audioUrl:
        "https://www.learningcontainer.com/wp-content/uploads/2020/02/Kalimba.mp3",
  ),
  BookDetails(
    isbn: "9780134685991",
    edition: "3rd Edition",
    pdfLink: "https://pdfobject.com/pdf/sample.pdf",
  ),
  BookDetails(
    isbn: "9780596007126",
    edition: "Illustrated Edition",
    pdfLink: "https://pdfobject.com/pdf/sample.pdf",
  ),
  BookDetails(
    isbn: "9780439139601",
    edition: "Special Edition",
    pdfLink: "https://pdfobject.com/pdf/sample.pdf",
    audioUrl:
        "https://www.learningcontainer.com/wp-content/uploads/2020/02/Kalimba.mp3",
  ),
];

// Mock current user for demo purposes
final User fakeCurrentUser = User(
  email: 'jane.doe@example.com',
  name: 'Jane Doe',
  joinDate: DateTime(2023, 2, 14),
  userType: 'regular',
  buyerFlag: true,
  sellerFlag: false,
);
